module Spree
  class ShipmentHandler
    class << self
      def factory(shipment)
        # Do we have a specialized shipping-method-specific handler? e.g:
        # Given shipment.shipping_method = Spree::ShippingMethod::DigitalDownload
        # do we have Spree::ShipmentHandler::DigitalDownload?
        if sm_handler = "Spree::ShipmentHandler::#{shipment.shipping_method.name.split('::').last}".safe_constantize
          sm_handler.new(shipment)
        else
          new(shipment)
        end
      end
    end

    def initialize(shipment)
      @shipment = shipment
    end

    def perform
      shipped_ius = []
      @shipment.inventory_units.each do |iu|
        shipped_ius << iu.id if iu.can_ship? && iu.ship!
      end
      @shipment.process_order_payments if Spree::Config[:auto_capture_on_dispatch]
      @shipment.touch :shipped_at
      update_order_shipment_state
      send_shipped_email if @shipment.inventory_units.count.eql?(shipped_ius.compact.count)
    end

    private

    # def send_shipped_email
    #   if @shipment.order.store.ses_emails
    #     SesEmailsDataWorker.perform_async(@shipment.id, "regular_shipment_customer")
    #   else
    #     ShipmentMailer.shipped_email(@shipment.id).deliver_now
    #   end
    # end

    def update_order_shipment_state
      order = @shipment.order

      new_state = OrderUpdater.new(order).update_shipment_state
      order.update_columns(shipment_state: new_state, updated_at: Time.current)
    end
  end
end
