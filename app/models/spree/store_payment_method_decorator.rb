module Spree
  module StorePaymentMethodDecorator
    def self.prepended(base)
      base.belongs_to :store, class_name: 'Spree::Store'
      base.belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

      base.enum apple_pay_domains: { empty: 1, default_domain: 2, store_domain: 3, both: 4 }
    end
  end
end

::Spree::StorePaymentMethod.prepend Spree::StorePaymentMethodDecorator if ::Spree::StorePaymentMethod.included_modules.exclude?(Spree::StorePaymentMethodDecorator)
