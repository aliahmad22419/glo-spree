module Spree
  module V2
    module Storefront
      class PaymentSerializer < BaseSerializer
        set_type :payment

        attributes :amount, :source_type, :payment_method_id, :state, :response_code
        
        attribute :payment_method do |object|
          Spree::V2::Storefront::PaymentMethodSerializer.new(object.payment_method).serializable_hash
        end
        
      end
    end
  end
end
