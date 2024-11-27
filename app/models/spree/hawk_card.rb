module Spree
  class HawkCard < Spree::Base
    belongs_to :user, :class_name => 'Spree::User'
    belongs_to :order, :class_name => 'Spree::Order'
    belongs_to :line_item, :class_name => 'Spree::LineItem'
  end
end
