module Spree
  module RefundDecorator

    def self.prepended(base)
      base.belongs_to :order, class_name: "Spree::Order"
      base.belongs_to :created_by, class_name: "Spree::User", foreign_key: "user_id"

      # REASONS = { csr_lead_request: 'As per supplied on CS Dashboard' }.freeze

      base.after_initialize :attach_refund_reason_and_payment, if: :new_record?
      base.after_create_commit :send_order_tag_email
    end

    private

    # Assuming only one completed payment will exist
    def attach_refund_reason_and_payment
      self.payment = self.order.payments.joins(:payment_method).find_by(
        state: 'completed', spree_payment_methods: { type: 'Spree::Gateway::StripeGateway' }
      )

      unless self.payment.present?
        self.errors.add(:base, 'No payment found to refund')
        throw :abort
      end

      client_refund_reasons = self.order.store.client.refund_reasons
      self.reason ||= client_refund_reasons.find_or_create_by(name: self.notes.to_s.strip)
    end

    def process!(credit_cents)
      # Need to override spree core as cents are calculated differently for different currencies
      # consider JPY is non decimal, USD is 2 decimal and BHD is 3 decimal etc
      credit_cents = self.order.amount_in_cents(amount, self.order.currency)

      response = if payment.payment_method.payment_profiles_supported?
                   payment.payment_method.credit(credit_cents, payment.source, payment.transaction_id, gateway_options)
                 else
                   payment.payment_method.credit(credit_cents, payment.transaction_id, gateway_options)
                 end

      response = stripe_response_methods(response)
      unless response.success
        #  render json: response, status: response.code

        Rails.logger.error(Spree.t(:gateway_error) + "  #{response.to_yaml}")
        text = response.message || response[:response_reason_text] || response.message
        raise Exception.new text
      end

      response
    end

    def gateway_options
      Spree::Payment::GatewayOptions.new(self.payment).to_hash
    end

    def stripe_response_methods(response)
      def response.message
        self[:message] if self.key?(:message)
      end

      def response.authorization
        self[:authorization] if self.key?(:authorization)
      end

      def response.success
        self[:success] if self.key?(:success)
      end
      response
    end

    def amount_is_less_than_or_equal_to_allowed_amount
      # if self.amount > payment.credit_allowed
      #   errors.add(:amount, :greater_than_allowed)
      # end
      if self.amount > (self.order.price_values(self.order.currency)[:prices][:payable_amount].to_f - self.order.refunds.sum(:amount))
        errors.add(:amount, :greater_than_allowed)
      end
    end

    def send_order_tag_email
      client = order.store.client

      refund_type = if (self.order.payments.completed.sum(&:amount) - self.order.refunds.sum(:amount)).positive?
        "Partially Refunded"
      else "Refunded" end

      # find client's refund tag and assign to order
      order_tag = client.order_tags.find_by(label_name: refund_type)
      unless order.order_tags.ids.include?(order_tag.id)
        order.order_tags << order_tag
        order.update_sale_analyses if order.save!
      end

      # send email
      order_tag_order = Spree::OrderTagsOrder.find_by(order_tag_id: order_tag.id, order_id: self.order_id)
      order_tag_order.send_email_tag_added_to_intimation
    end
  end
end

::Spree::Refund.prepend Spree::RefundDecorator if ::Spree::Refund.included_modules.exclude?(Spree::RefundDecorator)
