module Spree
  module Api
    module V2
      module Storefront
        class LinkPaymentsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :set_link, except: :adyen_payment_link_notification
          before_action :load_link_notification, :authorize_link_notification, only: :adyen_payment_link_notification
          before_action :validate_regeneration_time, only: :regenerate

          def adyen_payment_link_notification
            acknowledgment = "[accepted]"
            # Log notification received
            @link.webhook_responses.create(details: {key: 'Received', value: @notification.to_s}.to_s)
            if @notification["success"] == "true"
              @link.update(adyen_success_params)
              @link.payment.update(response_code: "##{@notification["pspReference"]}#")
            end
          rescue Exception => exception
            acknowledgment = exception.message
          ensure
            render_acknowledged(acknowledgment)
          end

          def regenerate
            @link.touch
            render json: @link.payment_method.regenerate(@link.payment)
          end

          private

          def set_link
            @link = Spree::LinkSource.find_by(gateway_reference: params['gateway_reference'])

            render_resource_not_found if @link.blank?
          end

          def authorize_link_notification
            if ["AUTHORISATION", "CAPTURE"].exclude?(@notification["eventCode"]) ||
                !valid_adyen_notification?(@notification, @link.payment_method.preferred_adyen_hmac_key)
              render json: { message: "Unauthorized request" }, status: :unauthorized 
            end
          end

          def load_link_notification
            @notification = params.dig("notificationItems",0,"NotificationRequestItem")
            @order = Spree::Order.find_by(number: @notification["merchantReference"]&.[](/R\d+/))
            @link = Spree::LinkSource.pending.find_by(gateway_reference: @notification.dig('additionalData','paymentLinkId'))

            if @link.blank? && @order&.inclusive_payment_methods_types&.exclude?("Spree::Gateway::LinkPaymentGateway")
              render_acknowledged
            elsif @link.blank? || @order&.complete? || @order != @link.payment.order
              render_resource_not_found
            end
          end

          def adyen_success_params
            data = @notification["additionalData"]
            attributes = { state: :completed }
            return attributes if data.blank?

            attributes.merge({ meta: {
              psp_reference: @notification["pspReference"],
              issuer_country: data["issuerCountry"],
              card_holder: data["cardHolderName"],
              card_summary: data["cardSummary"],
              card_bin: data["cardBin"]
            }})
          end

          def validate_regeneration_time
            time_out = (@link.updated_at + 5.minutes - DateTime.now) / 60

            if time_out.positive?
              sec = ((time_out - min = time_out.to_i) * 60).round
              sec = min.to_s + ' minute'.pluralize(min) + " " + sec.to_s + ' second'.pluralize(sec)

              render json: { error: "Retry in #{sec}", updated_at: @link.updated_at }, status: 422
            end
          end

          def valid_adyen_notification?(data, key)
            Adyen::Utils::HmacValidator.new.valid_notification_hmac?(data, key)
          end

          def render_resource_not_found(error = "Resource Not Found")
            render json: { message: error }, status: :not_found
          end

          def render_acknowledged(acknowledgment = "[accepted]")
            render json: { message: acknowledgment }, status: :accepted
          end

        end
      end
    end
  end
end
