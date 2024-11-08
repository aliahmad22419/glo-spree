class ScheduledDeliveryOfCardsEmailWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'cards_to_be_generated_and_delivered'
  
    def perform
        Spree::Shipment.joins(:order).gift_card_shipments.scheduled_shipments(DateTime.now.utc.beginning_of_hour, DateTime.now.utc.end_of_hour).where( spree_orders: { state: 'complete' } ).find_each do |shipment|
            next if !shipment.shipping_method.scheduled_fulfilled
            GenerateTsCardsWorker.perform_async(shipment.id)
            FullfillDigitalShipmentWorker.perform_async(shipment.id) if DIGITAL_TYPES.include?(shipment.delivery_mode)
        end
    end
end