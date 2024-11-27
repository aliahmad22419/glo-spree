# all prices are finalized in terms of cents
module PaymentSplits
  extend ActiveSupport::Concern

  included do
    attr_accessor :commission
  end

  def payment_splits
    splitter.push({
      "amount": { "value": @commission.to_i, "currency": currency },
      "type": 'Commission',
      "reference": "platform-commission-order-#{number}"
    }.with_indifferent_access)
  end

  def splitter
    @commission = 0
    self.line_items.group_by(&:vendor).map do |vendor, line_items|
      prices = split_amounts(vendor, line_items)
      @commission += prices[:platform] * line_items[0].apply_exchange_rate(line_items[0].currency)
      split = {
        "amount": { "value": prices[:vendor].to_i, "currency": vendor.base_currency.name.upcase },
        "type": (vendor.adyen_account.present? ? 'MarketPlace' : 'Commission'),
        "reference": "split-vendor-#{vendor.id}-items-#{line_items.map(&:id).join(',')}"
      }.with_indifferent_access
      split["account"] = vendor.adyen_account.account_code if vendor.adyen_account.present?
      split
    end
  end

  def split_amounts(vendor, line_items)
    total = (line_items.sum(&:amount) + shipment_price(vendor)) * 100
    comm = platform_commission(total)
    { vendor: (total - comm), platform: comm }
  end

  def shipment_price(vendor)
    self.shipments.find{ |s| s.vendor_id == vendor.id }.cost rescue 0
  end

  def platform_commission(amount)
    return store.app_fee unless store.app_fee_type == APP_FEE_TYPES[:percentage]
    (store.app_fee * amount / 100).to_i
  end
end
