module Spree
  class TimeSlot < Spree::Base
    belongs_to :shipping_method, class_name: 'Spree::ShippingMethod'
  end
end
  