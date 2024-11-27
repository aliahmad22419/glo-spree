module Spree
  module Emails
    module ShipmentHandlerDecorator
      protected

      def send_shipped_email
        if @shipment.order.store.ses_emails
          SesEmailsDataWorker.perform_async(@shipment.id, "regular_shipment_customer")
        else
          ShipmentMailer.shipped_email(@shipment.id).deliver_now
        end
      end
  

      ::Spree::ShipmentHandler.prepend(self)
    end
  end
end


