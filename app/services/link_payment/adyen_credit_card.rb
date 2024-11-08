module LinkPayment
  class AdyenCreditCard < SourceGenerator
    def initialize(payment)
      super(payment)
      adyen_client
    end

    def generate
      rescue_from_connection do
        response = @links_api.payment_links({
          expiresAt: expiry_at_date,
          merchantAccount: @payment_method.preferred_merchant_account,
          reference: order_reference,
          amount: currency_amount
        })
        parsed_response("generate", response)
      end
    end

    def regenerate
      return @payment unless payment_link.parsed_response["status"].eql?("expired")
      @payment.source.failed!
      attach_payment
    end

    def expire
      response = @links_api.update_payment_link({status: 'expired'}, @payment.source.gateway_reference)
      parsed_response("expire_link", response)
    end

    def captured?
      response = payment_link
      Response.new(response.success? && response.parsed_response["status"].eql?("completed"), "purchase")
    end

    def refund(money, authorization, options)
      raise "Gateway refund not configured." unless @payment_method.webhook_configured?

      _, psp_reference, _ = authorization.split('#')
      rescue_from_connection do
        response = @links_api.refund(psp_reference, {
          amount: { currency: options[:currency], value: options[:amount] },
          reference: options[:order_reference_id],
          merchantAccount: @payment_method.preferred_merchant_account
        })
        parsed_response("refund", response)
      end

    end

    def expiry_at_date
      ((DateTime.now.next_day @payment_method.preferred_expires_in_days) - 1.hour ).strftime("%Y-%m-%dT%H:%M:%S%Z")
    end

    private
    def payment_link # Get adyen payment link
      @links_api.get_payment_link(@payment.source.gateway_reference)
    end

    def rescue_from_connection
      yield
    rescue Exception => exception
      raise Spree::Core::GatewayError.new exception.message
    end

    def adyen_client
      @links_api = LinkPayment::PaymentLinksApi.new(@payment_method)
    end

    def parsed_response(action ,response, options = {})
      data = response.parsed_response || {}

      if action == "refund"
        options.merge!(authorization: "##{data["pspReference"]}#")
      else
        data = link_source_data(response)
      end

      Response.new(response.success?, "action", data, options)
    end

    def link_source_data(response)
      data = response.parsed_response if response&.[]("status")

      if data && response.success?
        { status: :success, url: data["url"], gateway_reference: data["id"], expires_at: data["expiresAt"], meta: { link_status: data["status"] }}
      elsif data
        { status: response["status"], message: data["message"], error_code: data["errorCode"], meta: { status_code: data["status"], message: data["message"] } }
      else
        { status: :failed, meta: { message: response.message }}
      end
    end

    class Response
      attr_reader :params, :message, :test, :authorization, :avs_result, :cvv_result, :error_code, :emv_authorization

      def success?
        @success
      end

      def test?
        @test
      end

      def fraud_review?
        @fraud_review
      end

      def initialize(success, message, params = {}, options = {})
        @success, @message, @params = success, message, params.stringify_keys
        @test = options[:test] || false
        @authorization = options[:authorization]
        @fraud_review = options[:fraud_review]
        @error_code = options[:error_code]
        @emv_authorization = options[:emv_authorization]
        @avs_result = {}
        @cvv_result = {}
      end
    end

  end
end