module CurrencyFormatter
  extend ActiveSupport::Concern

  CURRENCIES_WITHOUT_FRACTIONS = %w(BIF CLP DJF GNF JPY KMF KRW MGA PYG RWF VND VUV XAF XOF XPF UGX)
  CURRENCIES_WITH_THREE_DECIMALS = %w(BHD JOD KWD OMR TND)

  def non_fractional_currency?(currency = 'USD')
    CURRENCIES_WITHOUT_FRACTIONS.include?(currency.upcase)
  end

  def three_decimal_currency?(currency = 'USD')
    CURRENCIES_WITH_THREE_DECIMALS.include?(currency.upcase)
  end

  def localized_amount(money, currency, decimal_places=0)
    amount = amount(money, decimal_places)
    amount = money # TODO need to support spree money object
    return amount unless non_fractional_currency?(currency) || three_decimal_currency?(currency)

    amount = money
    if non_fractional_currency?(currency)
      amount.split('.').first
    elsif three_decimal_currency?(currency)
      sprintf('%.3f', (amount.to_f / 10))
    end
  end

  def localized_amount_in_float amount, to_currency, decimal_places=0
    BigDecimal(localized_amount(amount, to_currency, decimal_places))
  end

  def amount(money, decimal_places)
    return 0 if money.nil?
    sprintf("%.#{decimal_places}f", money)
  end


  # currency formatter works only for store,
  # which means no store provide, no format will be applied
  def currency_formatter?(store=nil)
    store.present? && store.currency_formatter
  end

  def decimals_in_currency(decimals, currency)
    non_fractional_currency?(currency) ? 0 : decimals
  end

  def amount_in_cents(amount, currency)
    multiplier = (three_decimal_currency?(currency) ? 1000 : non_fractional_currency?(currency) ? 1 : 100)
    amount *= multiplier
    special_cases(amount.to_i, currency)
  end

  def special_cases(amount, currency)
    case currency
    when 'UGX'  # UGX is non-fractional currency
      amount * 100
    else
      amount
    end
  end
end
