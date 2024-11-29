module ActiveMerchant
  module Billing
    # module StripeGatewayDecorator
    #   def self.prepended(base)
    #     base.class_eval do
          # def add_destination(post, options)
          #   # if options[:destination]
          #   #   post[:transfer_data] = {}
          #   #   post[:transfer_data][:destination] = options[:destination]
          #   # end
          #   # FIXME it's here because active merchant billing adds emv checks before adding application_fee
          #   post[:application_fee] = options[:application_fee] if options[:application_fee]
          # end

          # being too lazy here, not me but spree (DUPLICATE just copy/paste ActiveMerchant)
          # def headers(options = {})
          #   key = options[:key] || @api_key
          #   idempotency_key = options[:idempotency_key]
          #
          #   headers = {
          #     'Authorization' => 'Basic ' + Base64.strict_encode64(key.to_s + ':').strip,
          #     'User-Agent' => "Stripe/v1 ActiveMerchantBindings/#{ActiveMerchant::VERSION}",
          #     'Stripe-Version' => api_version(options),
          #     'X-Stripe-Client-User-Agent' => stripe_client_user_agent(options),
          #     'X-Stripe-Client-User-Metadata' => {ip: options[:ip]}.to_json
          #   }
          #   headers['Idempotency-Key'] = idempotency_key if idempotency_key
          #   headers['Stripe-Account'] = options[:stripe_account] if options[:stripe_account]
          #   headers
          # end
    #     end
    #   end
    # end

    module AdyenGatewayDecorator
      def adyen_client(adyen_payment_method)
        return @client if @client.present?
        @client = Adyen::Client.new
        @client.env = adyen_payment_method.preferred_server.to_sym
        @client.api_key = adyen_payment_method.preferred_public_key
        @client.live_url_prefix = adyen_payment_method.preferred_live_url_prefix.to_s
        @client
      end

      def adyen_payment_methods(payment_method)
        begin
          adyen = adyen_client(payment_method)
          response = adyen.checkout.payment_methods({
            merchantAccount: payment_method.preferred_merchant_account,
            channel: 'Web'
          }).response
        rescue
          nil
        end
        response
      end

      def init_post(options = {})
        post = {}
        post[:merchantAccount] = options[:merchant_account] || @merchant_account
        post[:reference] = options[:order_id] if options[:order_id]
        amount = localized_amount(options[:amount], options[:currency])
        post[:amount] = { currency: options[:currency], value: amount }
        post
      end

      def authorize(money, payment, options={})
        requires!(options, :order_id)
        post = init_post(options)
        add_card(post, payment)
        add_address(post, options)
        add_3ds(post, options)
        # add_splits(post, options)
        commit_payment(post, payment, options)
      end

      def add_splits(post, options)
        return unless split_data = options[:splits]

        splits = []
        split_data.each do |split|
          amount = {}
          amount[:currency] = split['amount']['currency'] if split['amount']['currency']
          amount[:value] = localized_amount(split['amount']['value'], amount[:currency])

          split_hash = {
            amount: amount,
            type: split['type'],
            reference: split['reference']
          }
          split_hash['account'] = split['account'] if split['account']
          splits.push(split_hash)
        end
        post[:splits] = splits
      end

      def add_card(post, credit_card)
        card = {
          type: "scheme",
          encryptedExpiryMonth: credit_card.month,
          encryptedExpiryYear: credit_card.year,
          holderName: credit_card.name,
          encryptedCardNumber: credit_card.number,
          encryptedSecurityCode: credit_card.verification_value
        }

        card.delete_if { |k, v| v.blank? }
        card[:holderName] ||= 'Not Provided' if credit_card.is_a?(ActiveMerchant::Billing::NetworkTokenizationCreditCard)
        requires!(card, :encryptedExpiryMonth, :encryptedExpiryYear, :holderName, :encryptedCardNumber)
        post[:card] = card
      end

      def parsed_response(action, source, response)
        #note: it requires 3 arguments now but not varified by source code
        success = success_from(action, response)
        ActiveMerchant::Billing::Response.new(
          success,
          message_from(action, response),
          response,
          authorization: authorization_from(action, options, response),
          test: test?,
          error_code: success ? nil : error_code_from(response),
          avs_result: ActiveMerchant::Billing::AVSResult.new(code: avs_code_from(response)),
          cvv_result: ActiveMerchant::Billing::CVVResult.new(cvv_result_from(response))
        )
      end

      def add_original_reference(post, authorization, options = {})
        original_psp_reference, _, _ = authorization.split('#')
        post[:originalReference] = single_reference(authorization) || original_psp_reference
        add_reference(post, authorization, options) if post[:originalReference].blank?
      end

      def authorize3d(source)
        adyen = adyen_client(source.payment_method)
        response = adyen.checkout.payments.details({
          paymentData: source.three_ds_action['paymentData'],
          details: source.three_ds_action['data']
        })
        parsed_response("authorise", source, response.response)
      end

      def commit_payment(post, source, options)
        begin
          adyen = adyen_client(source.payment_method)
          response = adyen.checkout.payments({
            amount: post[:amount],
            # splits: post[:splits],
            reference: post[:reference],
            paymentMethod: post[:card],
            merchantAccount: post[:merchantAccount],
            shopperReference: options[:shopperReference],
            shopperInteraction: "Ecommerce",
            browserInfo: post[:browserInfo],
            billingAddress: post[:card][:billingAddress],
            # :shopperIP => "103.255.5.36",
            channel: options[:channel],
            origin: options[:site_origin],
            returnUrl: "#{options[:site_origin]}/#{options[:return_url]}&source=#{source.id}"
          })
        rescue ActiveMerchant::ResponseError => e
          raw_response = e.response.body
          response = parse(raw_response)
        end
        parsed_response("authorise", source, response.response)
      end

      def refund(money, authorization, options)
        originator = options[:originator]
        payment = originator.payment

        raise "Gateway refund not configured." unless payment.payment_method.webhook_configured?

        post = init_post(options)
        _, psp_reference, _ = authorization.split('#')
        adyen = adyen_client(payment.payment_method)

        response = adyen.payments.refund({
            originalReference: psp_reference,
            modificationAmount: { currency: options[:currency], value: options[:amount] },
            reference: post[:reference],
            merchantAccount: post[:merchantAccount]
        })

        parsed_response("refund", payment.source, response.response)
      end

    end
  end
end
# ActiveMerchant::Billing::StripeGateway.prepend(ActiveMerchant::Billing::StripeGatewayDecorator) #As no module is commented out.
ActiveMerchant::Billing::AdyenGateway.prepend(ActiveMerchant::Billing::AdyenGatewayDecorator)
ActsAsTaggableOn::Tag.table_name = :spree_tags
ActsAsTaggableOn::Tagging.table_name = :spree_taggings
