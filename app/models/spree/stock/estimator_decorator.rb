module Spree
  module Stock
    module EstimatorDecorator
      def shipping_rates(package, shipping_method_filter = Spree::ShippingMethod::DISPLAY_ON_FRONT_END)
        client = package.contents[0].inventory_unit.line_item.order.store.client
        free_shipment = client.shipping_methods.where("upper(name) = ?", "FREE SHIPPING").first
                          &.shipping_rates&.new(cost: 0.0)

        rates = calculate_shipping_rates(package, shipping_method_filter)
        free_included = rates.map(&:shipping_method_id).include?(free_shipment&.shipping_method_id)

        # Add free shipping by default to all packages
        rates << free_shipment if free_shipment.present? && !free_included
        # choose_default_shipping_rate(rates)
        sort_shipping_rates(rates)
      end

      private

      def calculate_shipping_rates(package, ui_filter)
        compromise_cost = package.contents.map {
          |content|
          store = content.inventory_unit.line_item.order.store
          content.inventory_unit.line_item.product.delivery_charges(store)
        }.max

        product = package.contents[0].inventory_unit.line_item.product

        shipping_methods(package, product.vendor_id, ui_filter).map do |shipping_method|
          cost, is_invalid = shipping_method.calculator.compute(package)
          next if is_invalid
          cost = cost.to_f - compromise_cost.to_f
          cost = 0.0 if cost < 0

          shipping_method.shipping_rates.new(
            cost: cost, # gross_amount(cost, taxation_options_for(shipping_method))
            tax_rate: first_tax_rate_for(shipping_method.tax_category)
          )
        end.compact
      end

      def first_tax_rate_for(tax_category)
        return unless @order.tax_zone && tax_category

        Spree::TaxRate.for_tax_category(tax_category).
          potential_rates_for_zone(@order.tax_zone).
            detect{ |rate| rate.tax_category == tax_category }
      end

      def shipping_methods(package, vendor_id, display_filter)
        # passing vendor_id to get shipping methods of only that vendor
        package.shipping_methods(vendor_id).select do |ship_method|
          calculator = ship_method.calculator

          ship_method.available_to_display?(display_filter) &&
            ship_method.include?(order.ship_address) &&
            calculator.available?(package) &&
            (calculator.preferences[:currency].blank? ||
            calculator.preferences[:currency] == currency)
        end
      end
    end
  end
end

::Spree::Stock::Estimator.prepend(Spree::Stock::EstimatorDecorator)
