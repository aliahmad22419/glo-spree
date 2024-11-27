
module Spree
  module PaymentMethodDecorator
    def self.prepended(base)
      base.has_many :store_payment_methods, dependent: :destroy
      base.has_many :stores, through: :store_payment_methods
      base.after_save :update_store_payment_methods
      base.scope :active_with_type, -> (type) { where(type: type, active: true).order(position: :asc) }
    end
    def payment_processable?
      true
    end

    def manual_capture?
      false
    end

    private

    def update_store_payment_methods
      self.store_payment_methods.where('payment_option NOT IN (?)', self.payment_options).destroy_all
    end
  end
end

::Spree::PaymentMethod.prepend(Spree::PaymentMethodDecorator)
