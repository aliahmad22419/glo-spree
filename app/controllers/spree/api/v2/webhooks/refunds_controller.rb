module Spree
  module Api
    module V2
      module Webhooks
        class RefundsController < ::Spree::Api::V2::BaseController
          before_action :load_refund_notification, :authorize_refund_notification, :log_notification, only: :adyen_refund_notification

          def adyen_refund_notification
            acknowledgment = "[accepted]"
            @refund.private_metadata = @refund.private_metadata.merge(reason: @notification["reason"])
            @refund.state = @notification["success"] == "true" ? :succeeded : :failed
            @refund.save!
          rescue Exception => exception
            acknowledgment = exception.message
          ensure
            acknowledgement(acknowledgment)
          end

          private
          def authorize_refund_notification
            if ["REFUND"].exclude?(@notification["eventCode"]) || !valid_adyen_notification?
              render json: { message: "Unauthorized request" }, status: :unauthorized
            end
          end

          def load_refund_notification
            @notification = params.dig("notificationItems",0,"NotificationRequestItem")
            @order = Spree::Order.complete.find_by(number: @notification["merchantReference"]&.[](/R\d+/))
            @refund = @order.refunds.pending.find_by(transaction_id: "##{@notification["pspReference"]}#") if @order.present?
            payment = @order.payments.completed.find_by(response_code: "##{@notification["originalReference"]}#") if @order.present?

            acknowledgement unless @refund.present? && payment.present?
          end

          def log_notification
            @refund.webhook_responses.create(details: {key: 'Received', value: @notification.to_s}.to_s)
          end

          # def valid_adyen_notification?(data, key)
          #   Adyen::Utils::HmacValidator.new.valid_notification_hmac?(data, key)
          # end

          def valid_adyen_notification?
            request.headers['Authorization'] == "Basic #{@refund.payment.payment_method.webhook_token}"
          end

          def acknowledgement(acknowledgment = "[accepted]")
            render json: { message: acknowledgment }, status: :accepted
          end

        end
      end
    end
  end
end
