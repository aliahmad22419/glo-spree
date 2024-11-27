module Spree
  module Stock
    module AvailabilityValidatorDecorator
      def validate(line_item)
        variant_items = line_item.order.line_items.where(variant_id: line_item.variant_id).where.not(id: line_item.id) if line_item.order.present?
        variant_quantity = line_item.quantity
        unit_count = line_item.inventory_units.reject(&:pending?).sum(&:quantity)

        if variant_items.present?
          variant_quantity += variant_items.sum(&:quantity)
          unit_count += variant_items.sum{ line_item.inventory_units.reject(&:pending?).sum(&:quantity) }
        end

        return if unit_count >= variant_quantity

        quantity = variant_quantity - unit_count
        return if quantity.zero?

        return if item_available?(line_item, quantity)

        variant = line_item.variant
        display_name = variant.name.to_s
        display_name += " (#{variant.options_text})" unless variant.options_text.blank?

        line_item.errors[:quantity] << Spree.t(
          :selected_quantity_not_available,
          item: display_name.inspect
        )
      end

      private

      def item_available?(line_item, quantity)
        Spree::Stock::Quantifier.new(line_item.variant).can_supply?(quantity) && line_item.stock_status && bulk_order_availability?(line_item)
      end

      def bulk_order_availability?(line_item)
        return true unless line_item.order&.bulk_order.present?

        line_item.product.status == 'active'
      end
    end
  end
end

::Spree::Stock::AvailabilityValidator.prepend(Spree::Stock::AvailabilityValidatorDecorator)
