# Spree::ShipmentMailer.class_eval do
#   def set_prices
#     attrs = @order.price_values(nil, @shipment.vendor_id)
#     @line_items = attrs[:line_items]
#     line_item_ids = @shipment.line_items.map(&:id)
#     @line_items = @line_items.select { |line_item| line_item_ids.include?(line_item.id)}
#     @shipments = attrs[:shipments]
#   end

#   def shipped_email(shipment, resend = false)
#     @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
#     @order = @shipment.order
#     @store = @order.store
#     return if @store.preferred_disable_shipping_notification
#     @config = @store.email_config({type: 'shipping'})
#     set_prices
#     subject = (resend ? "[#{I18n.t(:resend).upcase}] " : '')
#     subject += "Great news! Your order is on its way!"
#     mail(to: @order.email, cc: cc_store_recipients(@order.store), subject: subject)
#   end
# end

module Spree
  module ShipmentMailerDecorator
    def set_prices
      attrs = @order.price_values(nil, @shipment.vendor_id)
      @line_items = attrs[:line_items]
      line_item_ids = @shipment.line_items.map(&:id)
      @line_items = @line_items.select { |line_item| line_item_ids.include?(line_item.id)}
      @shipments = attrs[:shipments]
    end

    def shipped_email(shipment, resend = false)
      @shipment = shipment.respond_to?(:id) ? shipment : Spree::Shipment.find(shipment)
      @order = @shipment.order
      @store = @order.store
      return if @store.preferred_disable_shipping_notification
      @config = @store.email_config({type: 'shipping'})
      set_prices
      subject = (resend ? "[#{I18n.t(:resend).upcase}] " : '')
      subject += "Great news! Your order is on its way!"
      mail(to: @order.email, cc: cc_store_recipients(@order.store), subject: subject)
    end

  end
end

::Spree::ShipmentMailer.prepend Spree::ShipmentMailerDecorator
