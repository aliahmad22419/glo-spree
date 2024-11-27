module Spree
  module Stock
    module CoordinatorDecorator
      def build_packages(packages = [])
        inventory_units.each do |inventories|
          @inventories = inventories
          stock_locations_with_requested_variants.each do |stock_location|
            packer = build_packer(stock_location, @inventories)
            packages += packer.packages
          end
        end
        packages
      end

      def shipments
        shipments = packages.map do |package|
          shipment = package.to_shipment.tap { |s| s.address_id = order.ship_address_id }
          # Spree::Stock::Package.remove_item(item)
          shipment if shipment.shipping_rates.present?
        end.compact
        shipments
      end

      private

      def requested_variant_ids
        @inventories.map(&:variant_id).uniq
      end
    end
  end
end

::Spree::Stock::Coordinator.prepend(Spree::Stock::CoordinatorDecorator)
