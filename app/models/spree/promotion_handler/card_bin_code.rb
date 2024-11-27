module Spree
  module PromotionHandler
    class CardBinCode
      attr_reader :order
      attr_accessor :error, :success

      def initialize(order)
        @order = order
        @client = @order.store.client
      end

      def activate
        promotions.each do |promotion|
          if promotion.eligible?(order)
            order.labels[:promo] = "Promo (#{promotion.name})" if promotion.activate(line_item: nil, order: order)
          else
            promotion.deactivate(line_item: nil, order: order)
          end
        end
      end

      private

      def promotions
        @client.promotions.active.where(
          id: Spree::Promotion::Actions::BinCodeDiscount.pluck(:promotion_id),
          code: nil,
          path: nil
        )
      end
    end
  end
end
