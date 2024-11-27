module Spree
  module CreditCardDecorator
    def self.prepended(base)
      base.clear_validators!
      base.with_options if: :require_card_numbers?, on: :create do
        validates :month, :year, numericality: { only_integer: true }
        validates :number, :verification_value, presence: true, unless: :imported
      end
      base.whitelisted_ransackable_attributes = %w[last_digits cc_type]
    end

    def admin_payment?
      true
    end

    def card_brand
      preferred_network = public_metadata["preferred_network"]
      (cc_type.to_s + (preferred_network.presence && " (#{preferred_network.split('_').map{|word| word.first.upcase}.join} Network)").to_s).presence ||
          (name == 'card' ? 'Stripe' : name)
    end
  end
end

Spree::CreditCard.prepend Spree::CreditCardDecorator
