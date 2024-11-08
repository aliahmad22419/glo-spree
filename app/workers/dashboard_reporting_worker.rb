class DashboardReportingWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'dashboard_reporting'

  def perform(order_id)
    order = Spree::Order.find(order_id)
    begin
      assgin_fulfilment_team(order)
      calculated_price_values(order_id)
      order_sale_analysis(order_id)
      vendor_order_sale_analysis(order_id)
    rescue => e
      Rails.logger.error(e.message)
    end
    # order_id = 1624
    order_currency = order.currency
    client = order.store.client
    client_currency = client.reporting_currency
    completed_at = order.completed_at
    completed_at_in_ms = completed_at.to_s&.to_datetime&.beginning_of_day&.strftime('%Q')
    total_amount = order.price_values(client_currency, nil, true)[:prices][:payable_amount].to_f
    order_hash = {order_id: order.id,total_amount:  total_amount, store_id: order.store_id, store_name: order.store&.name, completed_at: completed_at,
                  total_items: order.line_items.count, client_reporting_currency: client_currency, currency: order_currency, date_in_ms: completed_at_in_ms,
                  email: order.email}
    vendor_order_data = []
    line_items_data = []
    line_item_variants = []
    vendor_ids = order.line_items.pluck("vendor_id")
    vendors = Spree::Vendor.where(id: vendor_ids)
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
      total_items_per_vendor = line_items.sum(:quantity)
      total = order.price_values((vendor_base_currency_name || order.currency), vendor_id, true)[:prices][:payable_amount].to_f
      client_total_amount = order.price_values(client_currency, vendor_id, true)[:prices][:payable_amount].to_f
      vendor_order = {vendor_id: vendor_id, total_amount: total, order_id: order.id, from_currency: vendor_base_currency_name, to_currency: order_currency,
                      markup_or_down: markup_or_down_value, exchange_rate_value: exchange_rate_value, date_in_ms: completed_at_in_ms,
                      store_id: order.store_id, store_name: order.store&.name, total_items: total_items_per_vendor, client_total_amount:  client_total_amount,
                      client_reporting_currency: client_currency, client_order_count: index == 0?  1 : 0, vendor_order_count: 1}
      vendor_order_data.push(vendor_order)

      line_items.each do |item|
        client_price = item.price_values_for_report(client_currency, nil)[:amount].to_f
        quantity = item.quantity
        item_data = {vendor_price: (quantity * item.price), client_price: client_price, quantity: quantity, client_reporting_currency: client_currency,
                     order_id: order.id, from_currency: vendor_base_currency_name, to_currency: order_currency,
                     markup_or_down: markup_or_down_value, exchange_rate_value: exchange_rate_value, date_in_ms: completed_at_in_ms,
                     store_id: order.store_id, store_name: order.store&.name, vendor_id: vendor_id, sku: item.variant&.sku, name: item.variant&.name}
        line_items_data.push(item_data)
        line_item_variants.push(item_data.merge({client_id: item&.store&.client_id, variant_id: item&.variant_id || -1, line_item_id: item.id}))
      end
    end

    puts line_item_variants.to_json
    puts line_items_data.to_json
    puts vendor_order_data.to_json
    puts order_hash.to_json

    sqs = Aws::SQS::Client.new()
    sqs.send_message({
                       queue_url: ENV['REPORTING_QUEUE_URL'],
                       message_body: "Reporting Data",
                       message_attributes: {
                         "order" => {
                           string_value: "#{order_hash.to_json}",
                           data_type: "String"
                         },
                         "vendor_orders" => {
                           string_value: "#{vendor_order_data.to_json}",
                           data_type: "String"
                         },
                         "line_items" => {
                           string_value: "#{line_items_data.to_json}",
                           data_type: "String"
                         },
                         "line_item_variants" => {
                          string_value: "#{line_item_variants.to_json}",
                          data_type: "String"
                        }
                       }
                     })

    generate_spreadsheet_data(order, sqs)

  end

  def order_sale_analysis(order_id)
    order = Spree::Order.find(order_id)
    order.generate_sale_analysis
  end

  def vendor_order_sale_analysis(order_id)
    order = Spree::Order.find(order_id)
    order.generate_vendor_sale_analysis
  end

  def calculated_price_values(order_id)
    order = Spree::Order.find(order_id)
    order.store_calculated_price_values
  end

  def assgin_fulfilment_team(order)
    order.update_columns(zone_id:order.tax_zone(true)&.id) if (order.line_items.where("delivery_mode = ? OR delivery_mode = ?", "givex_physical", "tsgift_physical").any?)
  end

end

def generate_spreadsheet_data(order, sqs)
  Spree::UpdateOrderSpreadSheet.new(order.id,ENV['GOOGLESHEET_QUEUE_URL'],"Googlesheet Data").update_sheet
end

# {:order_id=>1624, :total_amount=>2210.27, :store_id=>2, :store_name=>"Singapore", :completed_at=>nil, :total_items=>2, :client_reporting_currency=>"USD", :currency=>"SGD"}
# {:vendor_id=>81, :total=>679.27, :order_id=>1624, :from_currency=>"USD", :to_currency=>"SGD", :markup_or_down=>0.0, :exchange_rate_value=>1.364}
# {:vendor_id=>5, :total=>1531.0, :order_id=>1624, :from_currency=>"SGD", :to_currency=>"SGD", :markup_or_down=>0.0, :exchange_rate_value=>1.0}
