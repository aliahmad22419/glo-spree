module Spree
  module Stock
    module ContentItemDecorator
      def amount
        (line_item.custom_price != 0 ? line_item.custom_price : line_item.price)
        # line_item.price
      end
    end
  end
end

::Spree::Stock::ContentItem.prepend(Spree::Stock::ContentItemDecorator)
