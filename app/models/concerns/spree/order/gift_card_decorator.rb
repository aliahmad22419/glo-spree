
module Spree
  class Order
    module GiftCardDecorator
      def self.included(base)
        extend ActiveSupport::Concern
      end

      def add_gift_card_payments(gift_card)
        payments.gift_cards.checkout.map(&:invalidate!) unless Spree::Config.allow_gift_card_partial_payments

        if gift_card.present?
          payment_method = gift_card.client.payment_methods
                            .where(type: "Spree::PaymentMethod::GiftCard").available.first

          raise "Gift Card payment method could not be found" unless payment_method
          # amount_to_take = gift_card_amount(gift_card, outstanding_balance_after_applied_store_credit)
          create_gift_card_payment(payment_method, gift_card, price_values[:prices][:payable_amount].to_f)
        end
      end

      def last_payment_is
        Spree::Config.allow_gift_card_partial_payments &&
        payments.valid.last&.source_type.eql?("Spree::GiftCard") &&
        (respond_to?(:price_values) && float_tp(price_values[:prices][:payable_amount]).zero?) ? 'partial' : 'complete'
      end

      private

      def create_gift_card_payment(payment_method, gift_card, amount)
        amount = [gift_card.current_value,  amount].min
        payments.create!(
          source: gift_card,
          payment_method: payment_method,
          amount: amount,
          state: 'checkout',
          response_code: gift_card.generate_authorization_code
        )
      end
    end
  end
end

::Spree::Order::GiftCard.prepend(Spree::Order::GiftCardDecorator)
