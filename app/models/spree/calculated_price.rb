module Spree
  class CalculatedPrice < Spree::Base
    belongs_to :calculated_price, polymorphic: true
    serialize :calculated_value, Hash
    serialize :meta, Hash
  end
end