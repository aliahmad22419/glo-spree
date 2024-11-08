module LinkPayment
  class PaymentLinksApi
    TEST_URL = "https://checkout-test.adyen.com/v70"
    LIVE_URL = "-checkout-live.adyenpayments.com/checkout/v70"

    def initialize(payment_method)
      @payment_method = payment_method
    end
  
    def payment_links(data)
      HTTParty.post("#{get_url}/paymentLinks", body: data.to_json, headers: api_auth)
    end

    def get_payment_link(payment_link_id)
      HTTParty.get("#{get_url}/paymentLinks/#{payment_link_id}", headers: api_auth)
    end

    def update_payment_link(data, payment_link_id)
      HTTParty.patch("#{get_url}/paymentLinks/#{payment_link_id}", body: data.to_json, headers: api_auth)
    end

    def refund(psp_reference, data)
      HTTParty.post("#{get_url}/payments/#{psp_reference}/refunds", body: data.to_json, headers: api_auth)
    end

    private
    def get_url
      @payment_method.preferred_test_mode ? TEST_URL : "https://#{@payment_method.preferred_live_url_prefix + LIVE_URL}"
    end

    def api_auth
      {"x-api-key" => @payment_method.preferred_api_key, "Content-Type" => "application/json"}
    end

  end
end
