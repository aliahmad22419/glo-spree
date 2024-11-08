class LineItemReportingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'line_item_variant_reporting'

  def perform(order_id)
    order =  Spree::Order.find(order_id)
    order_currency = order.currency

    client = order.store.client
    client_currency = client.reporting_currency

    completed_at = order.completed_at
    completed_at_in_ms = completed_at.to_s&.to_datetime&.beginning_of_day&.strftime('%Q')

    line_item_variants = []
  
    vendors = Spree::Vendor.where(id: order.line_items.pluck("vendor_id"))
    vendors.each_with_index do |vendor, index|

      vendor_id = vendor.id
      markup_or_down_value = 0
      exchange_rate_value = 0
      vendor_base_currency = vendor&.base_currency
      vendor_base_currency_name = vendor_base_currency&.name
      if vendor_base_currency.present?
        markup_or_down = vendor_base_currency.markups.where(name: order_currency).first
        markup_or_down_value = markup_or_down.value if markup_or_down.present?
        currency_exchange_rate = client&.currencies&.with_out_vendor_currencies&.where(name: vendor_base_currency_name)&.first
        current_rate_value = currency_exchange_rate&.exchange_rates&.where(name: order_currency)&.first&.value if currency_exchange_rate.present?
        exchange_rate_value = current_rate_value unless current_rate_value.blank?
      end
      line_items = order.line_items.where(vendor_id: vendor_id)

      line_items.each do |item|
        client_price = item.price_values_for_report(client_currency, nil)[:amount].to_f
        quantity = item.quantity
        variant_name = "-"
        if item&.variant&.product_id 
          variant_name = item&.variant&.name
        end
        item_data =  {
          vendor_price: (quantity * item.price), client_price: client_price || -1, quantity: quantity || -1, client_reporting_currency: client_currency || "-",
            order_id: order.id, from_currency: vendor_base_currency_name || "-", to_currency: order_currency || "-",
            markup_or_down: markup_or_down_value, exchange_rate_value: exchange_rate_value, date_in_ms: completed_at_in_ms,
            store_id: order&.store_id || -1, store_name: order&.store&.name || "-", vendor_id: vendor_id, sku: item&.variant&.sku || "-", name: variant_name , client_id: item&.store&.client_id || -1,
            variant_id: item&.variant_id || -1, line_item_id: item&.id
        }
        line_item_variants.push(item_data)
      end      
    end

    sqs = Aws::SQS::Client.new()
    sqs.send_message({
                       queue_url: ENV['LINE_ITEM_REPORTING_QUEUE_URL'],
                       message_body: "Line Item with Varaints Reporting Data",
                       message_attributes: {
                         "line_item_variants" => {
                           string_value: "#{line_item_variants.to_json}",
                           data_type: "String"
                         }
                       }
                     })
  end

end
