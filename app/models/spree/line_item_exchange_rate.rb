module Spree
  class LineItemExchangeRate < Spree::Base
    belongs_to :line_item, class_name: "Spree::LineItem"
  end
end
