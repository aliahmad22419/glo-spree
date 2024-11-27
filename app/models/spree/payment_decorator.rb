module Spree
  module PaymentDecorator

    STRIPE_PAYMENT_METHODS = ['wechat_pay', 'alipay', 'card', 'googlePay', 'applePay']   unless const_defined?(:STRIPE_PAYMENT_METHODS)

    STRIPE_WALLETS = ['wechat_pay', 'alipay'] unless const_defined?(:STRIPE_WALLETS)

    def self.prepended(base)
      base.include Spree::Webhooks::HasWebhooks
      base.scope :giftcard_invalidateable, -> { where(state: [ 'checkout', 'processing', 'pending', 'completed' ]) }
      base.scope :processable, -> { where(state: [ 'checkout', 'processing', 'pending' ]) }

      base.after_save :set_order_paid_partially
      base.after_create :generate_link_source, if: :link_payment?
      base.before_create :validate_pending_link, if: :link_payment?
      base.after_create :set_bulk_order_tag, if: Proc.new { order.bulk_order.present? }

      base.whitelisted_ransackable_associations = %w[source]
      base.whitelisted_ransackable_attributes = %w[state]
    end

    def amount=(amount)
      self[:amount] =
        case amount
        when String
          separator = I18n.t('number.currency.format.separator')
          number    = amount.delete("^0-9-#{separator}\.").tr(separator, '.')
          number.to_d if number.present?
        end || amount
    end

    # only to display FIXME should be in helpers
    def card_details
      card = OpenStruct.new({
        name: payment_method&.name,
        type: "",
        number: "",
        url: source.try(:url),
        gateway_reference: source.try(:gateway_reference),
        payment_option: meta&.[]('payment_option'),
        card_network: ""
      })

      type, digits = case source_type
        when "Spree::BraintreeCheckout"
          [source.braintree_card_type, source.braintree_last_digits.rjust(4, "x")] rescue ["", ""]
        when "Spree::AdyenCheckout"
          [source.card_details["paymentMethod"].to_s, source.card_details["cardSummary"].to_s.rjust(4, "x")] rescue ["", ""]
        when "Spree::PaypalExpressCheckout"
          (source&.transaction_id.present? ? ["", source&.transaction_id[-4..-1]&.rjust(source&.transaction_id.length, "x")] : ["",""])
        when "Spree::GiftCard"
          ["Gift Card", source.code[-4..-1]]
        when "Spree::LinkSource"
          [nil, source.display_number]
        else # Spree::CreditCard
          [source.card_brand, source.last_digits&.rjust(4, "x").to_s ] rescue ["", ""]
        end

      card.card_network << source.public_metadata['preferred_network'].to_s.gsub("_"," ") if source.respond_to?("public_metadata")
      card.type << (type.presence || card.name)
      card.number << digits
      card
    end

    private
    def link_payment?
      payment_method.type_of? 'LinkPaymentGateway'
    end

    def validate_pending_link
      payments = self.order.payments.joins(:payment_method).where.not(id: nil).where(
        state: 'checkout', spree_payment_methods: { type: 'Spree::Gateway::LinkPaymentGateway' })
      raise Spree::Core::GatewayError.new "Already Pending Link Exists" if payments.any?{ |p| p.source&.pending? }
    end

    def generate_link_source
      source_data = payment_method.generate(self)&.params
      source_attributes =
        if (source_data["status"] == :success)
          { state: :pending,
            url: source_data["url"],
            meta: source_data["meta"],
            expires_at: source_data["expires_at"],
            payment_method: payment_method,
            gateway_reference: source_data["gateway_reference"] }
        else
          { payment_method: payment_method,
            meta: source_data["meta"] }
        end

      self.source.update(source_attributes)

      raise Spree::Core::GatewayError.new source_data[:message] unless (source_data["status"] == :success)
    end

    def profiles_supported?
      return false if source.present? && STRIPE_PAYMENT_METHODS.include?(source.try(:name))
      payment_method.respond_to?(:payment_profiles_supported?) && payment_method.payment_profiles_supported?
    end

    def set_order_paid_partially
      is_partial = (order.price_values[:prices][:payable_amount].to_f > 0 && order.total_applied_gift_card > 0)
      order.update(paid_partially: is_partial)
    end

    def order_total_remaining
      # order_remaining_total.to_f
      BigDecimal(order.price_values(order.currency)[:prices][:payable_amount])
    end

    def set_bulk_order_tag
      return unless ( label_type = meta&.[]('payment_option') )
      client = order.bulk_order.client

      # find or create client's bulk payment tag and assign to order
      order_tag = client.order_tags.find_or_create_by(label_name: label_type, intimation_email: client.email)
      unless order.order_tags.ids.include?(order_tag.id)
        order.order_tags << order_tag
        order.update_sale_analyses if order.save!
      end
    end
  end
end

::Spree::Payment.prepend Spree::PaymentDecorator unless ::Spree::Payment.ancestors.include?(Spree::PaymentDecorator)
