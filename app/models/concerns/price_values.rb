module PriceValues
  extend ActiveSupport::Concern

  included do
    attr_accessor :exchanged_prices, :to_currency, :apply_current_rates
  end

  EXCHANGEABLE_CALCULATORS = ["FlatPercentItemTotal", "PercentOnLineItem", "DefaultTax"]
  CURRENCIES_WITHOUT_FRACTIONS = %w(BIF CLP DJF GNF JPY KMF KRW MGA PYG RWF UGX VND VUV XAF XOF XPF)

  def price_value_attrs vendor_id=nil, apply_exchnage_rate=false
    @line_items = self.line_items
    @shipments = self.shipments
    unless vendor_id.blank?
      @line_items = @line_items.where(vendor_id: vendor_id)
      @shipments = @shipments.where(vendor_id: vendor_id)
    end
    @line_items.each{ |line_item| apply_exchnage_rate ? line_item.price_values_for_report(@to_currency) : line_item.price_values(@to_currency) }
    { line_items: @line_items, shipments: @shipments }
  end

  def price_values to_currency=nil, vendor_id=nil, apply_exchnage_rate=false
    @to_currency = (to_currency || self.currency)
    @apply_current_rates = apply_exchnage_rate
    attrs = price_value_attrs(vendor_id, apply_exchnage_rate)
    totals = exchanged_totals
    self.exchanged_prices = {
      item_total: tp(totals[:item_total], @to_currency),
      total: tp(totals[:total], @to_currency),
      gc_total: tp(total_applied_gift_card, @to_currency),
      payable_amount: tp((float_tp(totals[:total], @to_currency) - float_tp(total_applied_gift_card, @to_currency)), @to_currency),
      cents: tp((float_tp(totals[:total], @to_currency) - float_tp(total_applied_gift_card, @to_currency)), @to_currency),
      sub_total: tp(totals[:item_total] + totals[:line_item_adjustment_total], @to_currency),
      ship_total: tp(totals[:ship_total], @to_currency),
      adjustment_total: tp(totals[:adjustment_total], @to_currency),
      included_tax_total: tp(totals[:included_tax_total], @to_currency),
      additional_tax_total: tp(totals[:additional_tax_total], @to_currency),
      tax_total: tp(totals[:included_tax_total] + totals[:additional_tax_total], @to_currency),
      promo_total: tp(totals[:promo_total], @to_currency),
      import_duty: tp(float_tp(store&.duty) * exchange_rate(@to_currency, store&.duty_currency), @to_currency),
      vendor_based_shipment: totals[:vendor_based_shiment],
      vendor_ship_addjustment: totals[:vendor_ship_addjustment],
      lineitem_prices: totals[:lineitem_prices],
      shipment_prices: totals[:shipment_prices]
    }
    exchanged_prices[:cents] = amount_in_cents(BigDecimal(self.exchanged_prices[:payable_amount]), @to_currency)
    exchanged_prices[:refund_allowed] = (BigDecimal(exchanged_prices[:payable_amount]) - refunds.sum(&:amount))

    return { prices: self.exchanged_prices, line_items: attrs[:line_items], shipments: attrs[:shipments] }
  end

  def adjusted_sum adjustments
    adjustments.reduce(0) do |sum, adj|
      flat_percent = adj.adjustable.promotions[0].actions[0].calculator.type.demodulize == "FlatPercent" rescue nil
      amount = adj.amount
      amount *= (adj.adjustable.apply_exchange_rate(@to_currency, nil, @apply_current_rates) rescue 1) if adj.adjustable_type == "Spree::LineItem" && flat_percent
      sum += adj.adjustable.float_tp(amount, @to_currency)
    end
  end

  # NOTE rescue zero if trying to multiply nil in case any value is nil accross price_value related methods
  def shipment_related shipments=@shipments
    shipment_prices = OpenStruct.new({cost:{}, ship_sum: 0, addjust_sum: 0, additional_tax: 0, promo_sum: 0, included_tax: 0, vendor_based_ship: {}, vendor_ship_addjustment: {} })
    shipments.reduce(shipment_prices) do |result, shipment|
      line_item = self.line_items.find_by(id: shipment.line_item_id)
      exchange_value = line_item.present? ? line_item.apply_exchange_rate(@to_currency, nil, @apply_current_rates) : 1
      exchanged_shipment = float_tp((shipment.cost * exchange_value rescue 0), @to_currency)
      result[:ship_sum] += exchanged_shipment
      result[:cost][shipment.id] ={
                                    "shipment_cost" =>  exchanged_shipment, 
                                    "additional_tax" => float_tp((shipment.additional_tax_total * exchange_value rescue 0), @to_currency), 
                                    "included_tax" => float_tp((shipment.included_tax_total * exchange_value rescue 0), @to_currency)
                                  }
      result[:addjust_sum] += float_tp((shipment.adjustment_total * exchange_value rescue 0), @to_currency)
      result[:additional_tax] += float_tp((shipment.additional_tax_total * exchange_value rescue 0), @to_currency)
      result[:promo_sum] += float_tp((shipment.promo_total * exchange_value rescue 0), @to_currency)
      result[:included_tax] += float_tp((shipment.included_tax_total * exchange_value rescue 0), @to_currency)
      result[:vendor_based_ship][shipment.vendor_id] = (result[:vendor_based_ship][shipment.vendor_id] || 0) + exchanged_shipment
      result[:vendor_ship_addjustment][shipment.vendor_id] = ((result[:vendor_ship_addjustment][shipment.vendor_id] || 0) + (shipment.adjustments.sum(&:amount) * exchange_value rescue 0))
      result
    end
  end

  def lineitem_related line_items=@line_items
    lineitem_prices = OpenStruct.new({addjust_sum: 0, additional_tax: 0, promo_sum: 0, included_tax: 0, amount: 0})
    line_items.reduce(lineitem_prices) do |result, line_item|
      promo_calculator = line_item.adjustments.find_by(source_type: "Spree::PromotionAction")&.source&.calculator
      tax_calculator = line_item.adjustments.find_by(source_type: "Spree::TaxRate")&.source&.calculator
      line_item_percent = EXCHANGEABLE_CALCULATORS.include?(promo_calculator&.type&.demodulize)
      tax_item_percent = EXCHANGEABLE_CALCULATORS.include?(tax_calculator&.type&.demodulize)

      if line_item.order.in_finalized_state?
        exchange_value = (line_item.present? ? line_item.apply_exchange_rate(@to_currency, nil, @apply_current_rates) : 1) rescue 1
      else
        exchange_value = (line_item.present? ? line_item.product.apply_exchange_rate(@to_currency, nil, @apply_current_rates) : 1) rescue 1
        exchange_value = 1 if line_item.order.single_page_order?
      end

      result[:addjust_sum] += float_tp((line_item.adjustment_total * (tax_item_percent ? exchange_value : 1) rescue 0), @to_currency)
      result[:additional_tax] += float_tp((line_item.additional_tax_total * exchange_value rescue 0), @to_currency)
      result[:promo_sum] += float_tp((line_item.promo_total * (line_item_percent ? exchange_value : 1) rescue 0), @to_currency)
      result[:included_tax] += float_tp((line_item.included_tax_total * exchange_value rescue 0), @to_currency)
      result[:amount] += float_tp(line_item.exchanged_prices[:amount], @to_currency)
      result
    end
  end

  def exchanged_totals
    shipment_prices = shipment_related
    lineitem_prices = lineitem_related
    {
      promo_total: (lineitem_prices.promo_sum + shipment_prices.promo_sum + adjusted_sum(adjustments.promotion.eligible)),
      adjustment_total: (lineitem_prices.addjust_sum + shipment_prices.addjust_sum + adjusted_sum(adjustments.eligible)),
      included_tax_total: (lineitem_prices.included_tax + shipment_prices.included_tax),
      additional_tax_total: (lineitem_prices.additional_tax + shipment_prices.additional_tax),
      total: (lineitem_prices.amount + lineitem_prices.addjust_sum + shipment_prices.addjust_sum +
        shipment_prices.ship_sum + adjusted_sum(adjustments.eligible)),
      ship_total: shipment_prices.ship_sum,
      item_total: lineitem_prices.amount,
      line_item_adjustment_total: (lineitem_prices.addjust_sum + adjusted_sum(adjustments.eligible)),
      vendor_based_shiment: shipment_prices.vendor_based_ship,
      vendor_ship_addjustment: shipment_prices.vendor_ship_addjustment,
      lineitem_prices: lineitem_prices,
      shipment_prices: shipment_prices
    }
  end
end
