module Spree
  class AdyenCheckout < ActiveRecord::Base # Spree::Base
    attr_accessor :three_ds_data

    has_one :payment, foreign_key: :source_id, as: :source, class_name: 'Spree::Payment'
    has_one :order, through: :payment
    belongs_to :payment_method, class_name: 'Spree::PaymentMethod'

    alias_attribute :encryptedCardNumber, :number
    alias_attribute :expiryMonth, :month
    alias_attribute :expiryYear, :year
    alias_attribute :brand, :cc_type
    alias_attribute :encryptedCvc, :verification_value
    alias_attribute :cvc, :verification_value

    def display_number
      "XXXX-XXXX-XXXX-#{card_details['cardSummary']}"
    end

    def actions
      %w{capture void credit}
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.failed? && !payment.void? && payment.response_code.present?
    end

    # Indicates whether its possible to credit the payment.  Note that most gateways require that the
    # payment be settled first which generally happens within 12-24 hours of the transaction.
    def can_credit?(payment)
      payment.completed? && payment.credit_allowed > 0
    end

    def has_payment_profile?
      gateway_customer_profile_id.present? || gateway_payment_profile_id.present?
    end

    def update_after_payment_process(response)
      self.status = response.result_code if response.try(:result_code).present?
      self.psp_reference = response.psp_reference if response.try(:psp_reference).present?
      self.three_ds_action = response.action_3ds if response.try(:action_3ds).present?
      self.card_details = response.additional_data if response.try(:additional_data).present?
      self.save
    end
  end
end
