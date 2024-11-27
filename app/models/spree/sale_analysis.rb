module Spree
  class SaleAnalysis < Spree::Base
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :line_item, class_name: 'Spree::LineItem'

    def product_card_type_with_ts_type
      card_type.present? ? card_type : ""
      # card_type.present? ? "#{card_type}#{(product_card_type.present? ? ' (' + product_card_type.to_s + ')' : "")}" : ""
    end
  end
end
