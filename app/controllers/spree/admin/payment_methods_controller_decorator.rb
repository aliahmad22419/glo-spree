module Spree
  module Admin
    module PaymentMethodsControllerDecorator
      def self.prepended(base)
        base.after_action :braintree_merchant_accounts, only: [:update]
      end
      def braintree_merchant_accounts
        merchant_accounts = {}
        if params[:preferred_currency_merchant_accounts]
          params[:preferred_currency_merchant_accounts].each do |account|
            currency, merchant_account_id = account.split(':')
            merchant_accounts[currency] = merchant_account_id
          end
          @payment_method.preferred_currency_merchant_accounts = merchant_accounts
          @payment_method.save
        end
      end
    end
  end
end

::Spree::Admin::PaymentMethodsController.prepend Spree::Admin::PaymentMethodsControllerDecorator if ::Spree::Admin::PaymentMethodsController.included_modules.exclude?(Spree::Admin::PaymentMethodsControllerDecorator)
