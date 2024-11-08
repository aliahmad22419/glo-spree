class MarkOrderWithLalamoveStatusWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'mark_order_with_lalamove_status'

  def perform params
    params = JSON.parse(params)
    return if params["data"].blank? || params["data"]["order"].blank?
    lalamove_order_id = params["data"]["order"]["orderId"]
    lalamove_order_status = params["data"]["order"]["status"]
    return if lalamove_order_id.blank? || lalamove_order_status.blank?
    shipment = Spree::Shipment.find_by(lalamove_order_id: lalamove_order_id)
    return if shipment.blank?
    order = shipment.order
    store = order.store
    if lalamove_order_status == "PICKED_UP"
      if store.lalamove_pickup_order_tag_id
        order_tag = Spree::OrderTagsOrder.find_or_create_by(order_tag_id: store.lalamove_pickup_order_tag_id, order_id: order.id)
        order_tag.send_email_tag_added_to_intimation
      end
    elsif  lalamove_order_status == "COMPLETED"
      if store.lalamove_complete_order_tag_id
        order_tag = Spree::OrderTagsOrder.find_or_create_by(order_tag_id: store.lalamove_complete_order_tag_id, order_id: order.id)
        order_tag.send_email_tag_added_to_intimation
      end
      shipment.update_attribute(:tracking, lalamove_order_id)
      shipment.shipped! if shipment.can_shipped?
    end
  end
end