module Spree
  module Stock
    module PackerDecorator
      def packages
        if splitters.empty?
          [default_package]
        else
          build_splitter.split [default_package]
        end
        [default_package]
      end

      # default_package method is logically overridden to cater custom-options line_items missing issue.
      # Replaced inventory_units.index_by(&:variant_id).each with inventory_units.each because
      # group by variant_id yields single inventory_unit from each variant. Owing to that,
      # all inventory_units weren't added in package. Ultimately, those remaining inventory_units and
      # their respective line_items were not added in shipment(s).
      def default_package
        package = Spree::Stock::Package.new(stock_location)
        inventory_units.each do |inventory_unit|
          variant = Spree::Variant.find(inventory_unit.variant_id)
          unit = inventory_unit.dup # Can be used by others, do not use directly
          if variant.should_track_inventory?
            next unless stock_location.stocks? variant

            on_hand, backordered = stock_location.fill_status(variant, unit.quantity)
            package.add(Spree::InventoryUnit.split(unit, backordered), :backordered) if backordered.positive?
            package.add(Spree::InventoryUnit.split(unit, on_hand), :on_hand) if on_hand.positive?
          else
            package.add unit
          end
        end
        package
      end
    end
  end
end

::Spree::Stock::Packer.prepend(Spree::Stock::PackerDecorator)
