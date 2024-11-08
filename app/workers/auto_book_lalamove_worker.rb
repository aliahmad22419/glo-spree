class AutoBookLalamoveWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'auto_book_lalamove'

  def perform order_id
    order = Spree::Order.find(order_id)
    shipments = order.shipments.where("delivery_pickup_date IS NOT NULL")
    return if shipments.blank?
    shipments.each do |shipment|
      shipping_method = shipment.shipping_method
      next if shipping_method.auto_schedule_lalamove.eql? false || shipping_method.auto_schedule_lalamove.nil?
      next if (shipment.delivery_pickup_date - DateTime.now).to_i > 30
      d = shipment.delivery_pickup_date
      t = shipment.delivery_pickup_time.split('-').last
      t = Time.parse(t)
      scheduled_at = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec, shipment.delivery_pickup_date_zone).utc.iso8601
      options = {shipment_id: shipment.id, scheduled_at: scheduled_at}
      result = Spree::Lalamove::Quotation.call(options: options)
      if result["success"]
        options = {shipment_id: shipment.id, remarks: ''}
        result = Spree::Lalamove::PlaceOrder.call(options: options)
      end
    end
  end
end
