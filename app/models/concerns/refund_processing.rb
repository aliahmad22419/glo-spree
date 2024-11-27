  module RefundProcessing

    def process!(credit_cents)
      # Need to override spree core as cents are calculated differently for different currencies
      # consider JPY is non decimal, USD is 2 decimal and BHD is 3 decimal etc
      credit_cents = self.order.amount_in_cents(amount, self.order.currency)

      response = if payment.payment_method.payment_profiles_supported?
                  payment.payment_method.credit(credit_cents, payment.source, payment.transaction_id, gateway_options)
                else
                  payment.payment_method.credit(credit_cents, payment.transaction_id, gateway_options.merge(originator: self))
                end
      response = handle_response(response)

      if response.success?
        self.state = payment.payment_method.webhook_refund? ? :pending : :succeeded 
        update_columns(state: state)
      else
        Rails.logger.error(Spree.t(:gateway_error) + "  #{response.to_yaml}")
        text = response.message || response[:response_reason_text] || response.message
        raise Exception.new text
      end

      response
    rescue ActiveMerchant::ConnectionError => e
      Rails.logger.error(Spree.t(:gateway_error) + "  #{e.inspect}")
      raise Core::GatewayError, Spree.t(:unable_to_connect_to_gateway)
    end

    private
    def gateway_options
      Spree::Payment::GatewayOptions.new(self.payment).to_hash
    end

    def parsed_response(response)
      def response.message
        self[:message] if self.key?(:message)
      end

      def response.authorization
        self[:authorization] if self.key?(:authorization)
      end

      def response.success?
        self[:success] if self.key?(:success)
      end

      def response.success
        self[:success] if self.key?(:success)
      end
      response
    end

    def handle_response(response)
      if payment.payment_method.is_a? Spree::Gateway::StripeGateway
        parsed_response(response)
      else
        response
      end
    end

  end