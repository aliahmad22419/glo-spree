module Spree
  module LineItems
    class FindByVariant
      def execute(order:, variant:, options: {})
        glo_api = options[:glo_api]
        line_item = if glo_api
          line_item_customizations_present?(order, variant, options)
        end
        # it'll always create new line_item for gift
        return nil if line_item&.product_type == "gift"
        if glo_api
          return nil unless line_item # add new line_item
        end
        # set quantity for existing line_item
        line_item = order.line_items.where(variant_id: variant.id)[0] unless glo_api
        line_item
      end

      def line_item_customizations_present?(order, variant, options)
        customizations_array = options[:customization_options]
        line_items = order.line_items.where(variant: variant)
        line_items.each do |line_item|
          customizations = line_item.line_item_customizations
          next unless customizations.count == customizations_array.to_a.count # filter based on count

          matching_customizations = []
          customizations_array.to_a.each do |opt|
            cust_array = line_item.line_item_customizations.where(customization_option_id: opt[:customization_option_id], value: opt[:value])
            break unless cust_array.any?
            matching_customizations << cust_array[0]
          end
          if matching_customizations.count == customizations_array.to_a.count
            return (customizations_array.blank? ? line_item : matching_customizations[0].line_item) # return line_item with same customizations
          end
        end
        return nil # no line_item with same customizations
      end
    end
  end
end
