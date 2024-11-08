module Spree
  class OrderMailer < BaseMailer
    # before_action do
    #   order = params[:order]
    #   vendor = params[:vendor]
        # attrs = order.price_values(nil, vendor.try(:id))
        # @line_items = attrs[:line_items]
        # @shipments = attrs[:shipments]
    # end

    def set_prices
      attrs = @order.price_values(nil, @vendor.try(:id))
      @line_items = attrs[:line_items]
      @shipments = attrs[:shipments]
    end

    def confirm_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @store = @order.store
      @config = @store.email_config({type: 'confirm'})
      set_prices
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "Thank you! We’ve got your order #{@order.number}"

      mail(to: @order.email, subject: subject, cc: cc_store_recipients(@store).uniq, bcc: (@store.enable_review_io ? [@store.reviews_io_bcc_email] : []))
    end

    def cancel_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      @store = @order.store
      @config = @store.email_config({type: 'confirm'})
      set_prices
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree.t('order_mailer.cancel_email.subject')} ##{@order.number}"
      mail(to: @order.email, subject: subject)
    end

    def vendor_confirmation(order, vendor, resend = false)
      @order = order
      @vendor = vendor
      @store = @order.store
      @config = @store.email_config({type: 'vendor'})
      set_prices
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "You've got an order...ready, set, dispatch order #{@order.number}!"
      mail(to: vendor.email, subject: subject, cc: (str_to_a(@vendor&.additional_emails) + cc_store_recipients(@order.store)).uniq)
    end

    def self.email_to_vendors(order)
      vendors = order.line_items.map{ |item| item.product.vendor }.compact.uniq
      vendors.each { |to| vendor_confirmation(order, to).deliver_now }
    end

    def send_monthly_sale_report(order)
      @order = order
      I18n.locale = @order.store.supported_locale.to_sym
      @logo = @order.store.client.active_storge_url(@order.store.client.logo)
      mail(to: str_to_a(@order.store.finance_report_to), cc: str_to_a(@order.store.finance_report_cc), subject: "Reconciliation Report")
    end
    # self.with(order: order, vendor: to).vendor_confirmation(order, to).deliver_now

    def notify_balance_due(order)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      set_prices
      subject = "Order completed with balance due."
      mail(to: 'rabia@techsembly.com', subject: subject, cc: ['ayesha@techsembly.com', 'bisma@techsembly.com', 'shigrif@techsembly.com'], bcc: ['zain@techsembly.com', 'zeeshan@techsembly.com'])
    end
  end
end
