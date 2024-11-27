module Spree
  class Promotion
    module Actions
      class BinCodeDiscount < PromotionAction
        include Spree::AdjustmentSource

        preference :store_bin_codes, :array, default: []

        def perform(options = {})
          order = options[:order]

          order.price_values # exchanged prices
          create_unique_adjustment(order, order)
        end

        def compute_amount(order)
          [order_total(order), compute(order)].min * -1
        end

        def order_total(order)
          return order.item_total unless order.exchanged_prices.present?

          BigDecimal(order.exchanged_prices[:item_total]) +
          BigDecimal(order.exchanged_prices[:ship_total]) -
          order.exchanged_prices[:shipment_prices].promo_sum
        end

        # As this calculator is specific for bin codes, added logic here instead of having new calculators
        def compute(order)
          return 0 unless order.exchanged_prices.present?

          return 0 if preferences['store_bin_codes'].blank?

          store_bincodes = preferences['store_bin_codes'].detect { |bins| bins.key(order.store_id.to_s) }&.fetch('bincodes')
          discount_hash = store_bincodes&.detect { |hsh| order.bincode.eql?(hsh['bin']) }
          return 0 unless discount_hash.present?

          computed_amount = BigDecimal(order.exchanged_prices[:item_total])
          discount = BigDecimal(discount_hash['discount'])

          amount = (discount_hash['calculator'].eql?('flat_rate') ? discount : order.float_tp(computed_amount * discount / 100))

          # We don't want to cause the promotion adjustments to push the order into a negative total.
          [amount, computed_amount].min
        end
      end
    end
  end
end
