class CurrencyPriceWorker
  def update_prices(id, options = {})
    attrs = {}
    product = Spree::Product.find id
    current_client = product.client
    current_vendor = product.vendor
    base_currency = current_vendor.base_currency.name rescue nil
    return if current_client.blank?

    attrs = { client_id: current_client.id }
    to_currencies = current_client.supported_currencies
    to_currencies = [options['currency']].flatten if options['currency'].present?
    to_currencies.uniq!

    to_currencies.each do |to_currency|
      attrs.merge!({to_currency: to_currency})
      product_currency_price = product.product_currency_prices.find_by(attrs)
      product_currency_price ||= product.product_currency_prices.new(attrs)
      product_currency_price.vendor_id = current_vendor.try(:id)
      product_currency_price.local_store_ids = current_vendor.try(:local_store_ids).to_a
      rate = product.exchange_rate(to_currency)
      product_currency_price.exchange_rate_value = rate
      product_price = product.price.to_f
      product_currency_price.from_currency = (base_currency || "USD")
      product_currency_price.non_exchanged_price = product_price
      product_currency_price.price = product_price * rate
      # to_f as prices may be nil
      product_currency_price.sale_price = product.sale_price.to_f * rate
      product_price = product.sale_price.to_f if product.on_sale?

      taxs = []
      product.stores.each do |store|
        next unless store.present?
        tax_rate = store.default_tax_zone&.tax_rates
                       &.where('tax_category_id = ? AND included_in_price = ? OR included_in_price IS NULL', product.tax_category_id, false)
                       &.order(id: :desc)
        tax_percentage = (tax_rate.present? ? tax_rate[0].amount : 0)
        taxs.push("store#{store.id.to_s}:#{((product_price + product.delivery_charges(store)) * tax_percentage * rate)}-#{tax_percentage}")
      end
      product_currency_price.taxes = taxs

      product_currency_price.local_area_price = (product_price + product.local_area_delivery.to_f) * rate
      product_currency_price.wide_area_price = (product_price + product.wide_area_delivery.to_f) * rate
      product_currency_price.restricted_area_price = (product_price + product.restricted_area_delivery.to_f) * rate
      begin
        product_currency_price.save!
      rescue ActiveRecord::RecordInvalid => e
        is_duplicate = e.message.include? ("has already been taken")
        is_duplicate ? Rails.logger.warn("Price already exist for currency: " + to_currency) : (raise e.message)
      end
    end
    product.reload.reindex
    product.flush_cache
  end
end
