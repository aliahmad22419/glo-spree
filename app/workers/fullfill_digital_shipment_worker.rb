class FullfillDigitalShipmentWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'fullfill_digital_shipment'

  def perform shipment_id
    shipment = Spree::Shipment.find shipment_id
    shipment.acknowledged! if shipment.can_acknowledged?
    shipment.processing! if shipment.can_processing?
    shipment.shipped! if shipment.can_shipped?
    order_shipments = shipment.order.shipments
    shipment.order.update_attribute(:shipment_state, "shipped") if order_shipments.count == order_shipments.shipped.count
  end
end
