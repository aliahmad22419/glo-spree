module Spree
  module V2
    module Storefront
      class ShippingCategoriesSerializer < BaseSerializer
        set_type  :shipping_categories

        attribute :id ,:name,:is_weighted
      end
    end
  end
end
