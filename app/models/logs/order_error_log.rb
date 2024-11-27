class Logs::OrderErrorLog < ApplicationRecord
  belongs_to :order, :class_name => 'Spree::Order'
  belongs_to :line_item, :class_name => 'Spree::LineItem'

  enum error_type: [:shipment, :ts_card, :givex_card]
  enum status: [:failed, :successful, :unresolved, :exceeded]

  before_save -> { self.status = 'unresolved' }, if: -> { self.attempts == 3 && self.status == 'failed' }
  after_save :notify_issue, if: -> { order.store.preferred_enabled_error_logging && unresolved? }

  validates :error_type, :message, presence: true


  private

  def notify_issue
    email_body = {
        title: "Missing #{error_type.humanize.pluralize}",
        message: message,
        meta: order_meta_data(order, "Missing #{error_type.humanize.pluralize}")
    }
    
    ErrorLoggerWorker.new.notify_sns(email_body, { logger_sns_topic_arn: ENV['RETRY_ERROR_LOGGER_SNS_ARN'] })
  end

  def order_meta_data(order, reason)
    data = {
        customer_email: order.email,
        store_name: order.store.name,
        order_id: order.id,
        order_number: order.number,
        complete_order: order.serializable_hash,
        order_status: order.status,
        order_state: order.state,
        logs: "Customer Email: #{order.email}\nAccount Name: #{order.store.client.name || 'N/A'}\nStore Name: #{order.store.name}\nOrder ID: #{order.id}\nOrder #: #{order.number}\nOrder State: #{order.state}\nReason: #{reason}\n"
    }
    data[:logs] += line_item.error_log_product_details
    data
  end
end
