module Spree
  class OrderTagsOrder < Spree::Base
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :order_tag, class_name: 'Spree::OrderTag'

    def send_email_tag_added_to_intimation
      template = "order_tag_added_store_" + ENV['SES_ENV'] + "_" + order.store.id.to_s
      send_email(template)
    end

    def send_email_tag_removed_to_intimation
      template = "order_tag_removed_store_" + ENV['SES_ENV'] + "_" + order.store.id.to_s
      send_email(template)
    end

    def send_email template
      return unless order_tag.intimation_email
      data = {"order_number" => order.number, "label" => order_tag.label_name}
      to_addresses = order_tag.intimation_email.split(',')&.map(&:strip)
      from_address = order.store&.mail_from_address
      SendSesEmailsWorker.perform_async(template, data, to_addresses, from_address)
    end
  end
end
