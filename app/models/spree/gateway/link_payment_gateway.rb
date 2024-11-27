module Spree
  class Gateway::LinkPaymentGateway < Gateway
    preference :api_key, :string
    preference :merchant_account, :string
    preference :live_url_prefix, :string
    preference :adyen_hmac_key, :string
    preference :link_type, :string, default: 'LinkPayment::AdyenCreditCard' #must have service as type i.e LinkPayment::AdyenCreditCard
    preference :expires_in_days, :integer, default: 70
    preference :webhook_user, :string
    preference :webhook_password, :string

    def auto_capture?
      true
    end

    def payment_processable?
      true
    end

    def source_required?
      true
    end

    def webhook_refund?
      true
    end

    def purchase(money, source, options = {})
      generator(source.payment).captured?
    end

    def credit(money, response_code, gateway_options)
      generator(gateway_options[:originator].payment).refund(money, response_code, refund_options(gateway_options, money))
    end

    def regenerate(payment)
      regenerated_payment = generator(payment).regenerate  
      regenerated_payment.reload.source
    end

    def generate(payment)
      generator(payment).generate
    end

    def expire(payment)
      response = generator(payment).expire
      response.success? ? payment.source.expired! : response.params
    end

    def cancel(response); end

    def payment_source_class
      Spree::LinkSource
    end

    def provider_class
      Spree::Gateway::LinkPaymentGateway
    end

    def generator(payment)
      @generator ||= generator_class.new(payment)
    end

    def generator_class
      preferred_link_type.constantize
    end

    def webhook_token
      Base64.strict_encode64("#{preferred_webhook_user}:#{preferred_webhook_password}")
    end

    # this method preffered basic auth over hmac because we use basic auth for refunds
    def webhook_configured?
      (preferred_webhook_user.present? && preferred_webhook_password.present?) || preferred_adyen_hmac_key.present?
    end

    def refund_options(gateway_options, money)
      gateway_options.merge!(
        amount: money
      )
    end
  end
end
