module Spree
  class Printables::TsGiftcard::GiftcardView < Printables::BaseView
    attr_accessor :config

    def after_save_actions
      increase_invoice_number! if use_sequential_number?
    end

    def pdf_config
      @config ||= (printable.store&.gift_card_pdf&.preferences&.[](self.card_type) || Spree::GiftCardPdf::DEFAULT_CONFIG)
    end

    [:card_type, :expiry_date, :currency].each do |meth_name|
      define_method meth_name do
        (JSON.parse(printable.response)['value'][meth_name.to_s] || JSON.parse(printable.response)[meth_name.to_s])&.to_sym
      end
    end

    def card_number
      printable.number
    end

    def product_name
      printable&.line_item&.product&.name
    end

    def currency_symbol
      Spree::Money.new(self.card_currency)&.currency&.symbol
    end

    def card_currency
      self.currency.presence || printable.order&.currency
    end

    def short_description
      printable&.line_item&.product&.description
    end

    def long_description
      printable&.line_item&.product&.long_description
    end

    def logo_url
      printable&.store&.active_storge_url(printable&.store&.logo)
    end

    def delivery_details
      printable&.line_item&.product&.delivery_details
    end

    private

    def firstname
      printable.customer_first_name
    end

    def lastname
      printable.customer_last_name
    end

    def email
      printable.customer_email
    end

    def number
      Spree::PrintInvoice::Config.next_number if use_sequential_number?
    end

    def total
      printable.balance
    end

  end
end
