module Spree
  module V2
    module Storefront
      class PaymentMethodSerializer < BaseSerializer
        set_type :payment_method

        attributes :type, :display_on, :auto_capture, :name, :description, :active, :payment_options

        attribute :api_preferences do |object|
          if object.is_a?(Spree::Gateway::AdyenGateway)
            object.preferences.slice(:server)
          else
            {}
          end
        end

        attribute :payable_options do |object, params|
          store_methods = Spree::StorePaymentMethod.where(store_id: params[:store].try(:id), payment_method_id: object.id)
          store_methods.select(:payment_option, :payment_option_display)
        end

        attribute :linked_methods do |object|
          if object.is_a?(Spree::Gateway::AdyenGateway)
            methods = object.provider.adyen_payment_methods(object)
            methods['paymentMethods'] = methods['paymentMethods'].select { |pm| pm['name'].present? && pm['name'].eql?('Credit Card')} unless methods.blank?
            methods
          end
        end

        attribute :preferences do |object, params|
          user = params[:user] 
          if user && ((user.has_spree_role?('client') || user.has_spree_role?('sub_client')) && (user.client_id.presence == object.client_id.presence))
            object.preferences
          else
            {}
          end
        end
      end

    
    end
  end
end
