module Spree
  module Stock
    module PackageDecorator
      def to_shipment
        # At this point we should only have one content item per inventory unit
        # across the entire set of inventory units to be shipped, which has been
        # taken care of by the Prioritizer
        contents.each { |content_item| content_item.inventory_unit.state = content_item.state.to_s }
        line_item = contents[0].inventory_unit.line_item
        Spree::Shipment.new(
          stock_location: stock_location,
          shipping_rates: shipping_rates,
          inventory_units: contents.map(&:inventory_unit),
          vendor_id: line_item.vendor_id,
          line_item_id: contents[0].inventory_unit.line_item_id,
          delivery_mode: line_item.delivery_mode,
          delivery_pickup_date: line_item.product.try(:effective_date) # daily stock pickup
        )
      end

      def shipping_methods vendor_id
        line_item_categories = self.shipping_categories.where(is_weighted: false).map{|shipping_category| shipping_category.name.upcase }
        weighted_categories = self.shipping_categories.where(is_weighted: true).map{|shipping_category| shipping_category.name.upcase }.uniq
        line_item_categories.uniq!
        line_item= contents[0].inventory_unit.line_item
        store = line_item.order.store
        client = store.client
        delivery_mode = line_item.delivery_mode
        delivery_mode = [nil, ""] if delivery_mode == "simple"

        shipping_methods = Spree::ShippingMethod.joins(:shipping_categories)
        shipping_methods = shipping_methods.where("spree_shipping_categories.id IN (?) AND store_ids @> ? AND (spree_shipping_methods.vendor_id = ? OR spree_shipping_methods.visible_to_vendors = ?)", client.shipping_category_ids, "{#{store.id}}", vendor_id, true).where(delivery_mode: delivery_mode)

        shipping_methods = if line_item.order.store.preferred_store_type == "iframe"
          shipping_methods.where(scheduled_fulfilled: line_item.shipment_scheduled?)
        elsif weighted_categories.present?
          shipping_methods.where("upper(spree_shipping_categories.name) IN (?)", weighted_categories)
        elsif line_item_categories.include?("LARGE")
          shipping_methods.where("upper(spree_shipping_categories.name) = 'LARGE'")
        elsif line_item_categories.include?("MEDIUM")
          shipping_methods.where("upper(spree_shipping_categories.name) = 'MEDIUM'")
        elsif line_item_categories.include?("SMALL")
          shipping_methods.where("upper(spree_shipping_categories.name) = 'SMALL'")
        else
          shipping_methods.where("upper(spree_shipping_categories.name) IN (?)", line_item_categories)
        end

        return [] if shipping_methods.blank?
        shipping_methods.uniq
      end
    end
  end
end

::Spree::Stock::Package.prepend(Spree::Stock::PackageDecorator)
