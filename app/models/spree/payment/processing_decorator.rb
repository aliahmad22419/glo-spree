module Spree
  class Payment
    module ProcessingDecorator
      def self.prepended(base)
        delegate :authorize3d, to: :provider
      end

      def process!
        if !payment_method&.payment_processable?
          proceed_without_process!
        elsif payment_method&.manual_capture?
          manual_capture!
        elsif payment_method&.auto_capture?
          purchase!
        else
          authorize!
        end
      end

      def proceed_without_process!
        send('complete')
      end

      def authorize3d!
        handle_payment_preconditions { process_authorize3d }
      end


      def manual_capture!(amount = nil)
        return true if completed?

        amount ||= money.amount_in_cents
        pend!
        protect_from_connection_error do
          # Standard ActiveMerchant capture usage
          response = payment_method.manual_capture(
            amount,
            self,
            gateway_options
          )
          money = ::Money.new(amount, currency)
          capture_events.create!(amount: money.to_f)
          split_uncaptured_amount
          response[:success] ? self.complete! : self.failure!
        end
      end

      private

      def process_authorize3d
        started_processing!
        gateway_action(source, :authorize3d, :complete)
      end

      def gateway_action(source, action, success_state)
        payable_amount = order.price_values(order.currency)[:prices][:payable_amount]
        payable_amount = BigDecimal(payable_amount) * 100
        payable_amount = money.amount_in_cents if source.is_a? Spree::GiftCard

        protect_from_connection_error do
          response = payment_method.send(action, payable_amount.to_i, source, gateway_options)
          response = (adyen_response_methods(response) || response)
          success_state = set_proper_state(success_state, response, action)
          handle_response(response, success_state, :failure)
        end
      end

      # just replace logger with Rails.logger
      def gateway_error(error)
        text = if error.is_a? ActiveMerchant::Billing::Response
                error.params['message'] || error.params['response_reason_text'] || error.message
              elsif error.is_a? ActiveMerchant::ConnectionError
                Spree.t(:unable_to_connect_to_gateway)
              else
                error.to_s
              end
        Rails.logger.error(Spree.t(:gateway_error))
        Rails.logger.error("  #{error.to_yaml}")
        raise Spree::Core::GatewayError, text
      end

      def handle_response(response, success_state, failure_state)
        record_response(response)

        if response.success?
          unless response.authorization.nil?
            self.response_code = response.authorization
            self.avs_response = response.avs_result['code']

            if response.cvv_result
              self.cvv_response_code = response.cvv_result['code']
              self.cvv_response_message = response.cvv_result['message']
            end
          end
          send("#{success_state}!")
        else
          send(failure_state)
          gateway_error(response)
        end
      end

      def set_proper_state(current_state, response, action)
        if source.is_a?(Spree::AdyenCheckout) && response.result_code.eql?('Authorised')
          'complete'
        else
          current_state
        end
      end

      def record_response(response)
        source.update_after_payment_process(response) if source.respond_to?(:update_after_payment_process)
        log_entries.create!(details: response.to_yaml)
      end

      def adyen_response_methods(response)
        return unless source.is_a?(Spree::AdyenCheckout)

        unless response.success?
          def response.to_s
            "#{params["resultCode"]} - #{params["refusalReason"]}"
          end
        end

        def response.action_3ds; params["action"]; end
        def response.psp_reference; params["pspReference"]; end
        def response.additional_data; params["additionalData"]; end
        def response.result_code; params["resultCode"]; end
        response
      end
    end
  end
end

::Spree::Payment::Processing.prepend  Spree::Payment::ProcessingDecorator

