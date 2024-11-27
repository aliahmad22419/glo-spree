module Exchangeable
  extend ActiveSupport::Concern
  include CurrencyFormatter

  ORDER_PREFERENCES = { single_page: false, decimal_points: 2, currency_formatter: false }.freeze

  def current_client
    @store = store if respond_to?(:store)
    @store ||= Spree::Store.find_by('spree_stores.id = ?', store_id) if respond_to?(:store_id)

    @client = @store&.client
    @client ||= client if respond_to?(:client)
    @client ||= Spree::Client.find_by('spree_clients.id = ?', client_id) if respond_to?(:client_id)
    @client
  end

  def load_data
    @order ||= if is_a?(Spree::Order)
                 self
               elsif is_a?(Spree::LineItem)
                 self.order
               end

    @store ||= try(:store)

    @config ||= if @order.present? && @order.completed_at.present?
                  @order.preferences
                elsif @store.present?
                  { single_page: @store.preferred_single_page, decimal_points: @store.decimal_points, currency_formatter: @store.currency_formatter }
                else ORDER_PREFERENCES end
  end

  def exchange_rate to_currency, from_currency=nil
    load_data
    return 1 if @config[:single_page]
    from_currency = current_client&.currencies&.with_out_vendor_currencies&.find_by(name: from_currency)
    exchange_rate_value = 1
    markup_or_down_value = 0
    return exchange_rate_value if to_currency.blank?
    vendor = (self.try(:vendor) || self.try(:product).try(:vendor))
    from_currency = vendor.base_currency if from_currency.blank? && vendor.present? && vendor.base_currency.present?
    if from_currency.present?
      from_currency_name = from_currency.name
      markup_or_down = from_currency.markups.where(name: to_currency).first
      markup_or_down_value = markup_or_down.value if markup_or_down.present?
      if from_currency_name.present?
        currency_exchange_rate = current_client&.currencies&.with_out_vendor_currencies&.where(name: from_currency_name)&.first
        current_rate_value = currency_exchange_rate&.exchange_rates&.where(name: to_currency)&.first&.value if currency_exchange_rate.present?
        exchange_rate_value = current_rate_value unless current_rate_value.blank?
        exchange_rate_value += (exchange_rate_value * markup_or_down_value/100) if markup_or_down_value != 0 && markup_or_down_value.present?
      end
    end
    return exchange_rate_value
  end

  def apply_exchange_rate to_currency, from_currency=nil, apply_current_rates=false
    load_data
    if self.class == Spree::LineItem
      return @config[:single_page] ? 1 :
        (self.try(:order).try(:in_finalized_state?) && !apply_current_rates) ? 
        saved_exchange_rate : self.variant&.product&.exchange_rate(to_currency, from_currency)
    elsif self.class == Spree::Order
      return 1 if self.try(:complete?)
    end
    self.exchange_rate(to_currency, from_currency)
  end

  # price_values must be called before executing this one
  def display_exchanged money_attr, vendor_id=nil
    amount = case money_attr
      when Symbol
        self.exchanged_prices[money_attr]
      else
        tp(money_attr, self.currency)
    end

    "#{currency} #{Spree::Money.new(currency: currency).currency.symbol} #{store_configured_currency_format(amount)}"
  end

  def store_configured_currency_format amount
    load_data
    store = (respond_to?(:order) ? order.store : try(:store))
    return amount unless @config[:currency_formatter]
    decimal_places = (non_fractional_currency?(currency) ? 0 : @config[:decimal_points])
    amount_positive = amount.to_f >= 0.0
    amount = amount.to_f.abs
    amount = "%.#{decimal_places}f" % amount
    whole, decimal = amount.to_s.split(".")
    num_groups = whole.chars.reverse.each_slice(3)
    whole_with_commas = num_groups.map(&:join).join(',').reverse
    whole_with_commas = amount_positive ? whole_with_commas : "-"+ whole_with_commas

    return whole_with_commas if decimal_places.zero?

    [whole_with_commas, decimal.to_s.ljust(decimal_places, '0')].compact.join(".")
  end

  def exchanged money_attr, to_currency=self.currency, from_currency=nil, apply_current_rates=false
    amount = case money_attr
      when Symbol
        send(money_attr)
      else
        money_attr
      end

    amount ||= 0
    exchanged_amount = apply_exchange_rate(to_currency, from_currency, apply_current_rates)
    (amount * exchanged_amount.to_f)
  end

  # TODO will be removed with localized_amount in module CurrencyFormatter
  def truncated_amount amount, to_currency = nil
    load_data
    to_currency ||= self.currency
    amount ||= 0
    @store ||= self.try(:store)
    amount = amount.to_f if amount.is_a? String

    return "%.2f" % amount if @config[:single_page]
    return "#{amount}" if !non_fractional_currency?(to_currency) && @store.nil?
    decimal_places = (non_fractional_currency?(to_currency) ? 0 : @config[:decimal_points])
    "%.#{decimal_places}f" % amount
  end

  # TODO will be removed with localized_amount_in_float in module CurrencyFormatter
  def truncated_amount_to_float amount, to_currency=self.currency, store=nil
    @store ||= store
    truncated_amount(amount, to_currency).to_f
  end

  def exchanged_adjustment_label obj, to_currency=currency
    { label: obj.label, amount: tp(obj.amount * apply_exchange_rate(to_currency), to_currency) }
  end

  alias_method :tp, :truncated_amount
  alias_method :float_tp, :truncated_amount_to_float
end
