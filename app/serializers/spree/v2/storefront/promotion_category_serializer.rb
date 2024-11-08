module Spree
  module V2
    module Storefront
      class PromotionCategorySerializer < BaseSerializer
        set_type  :promotion_categories

        attribute :id, :name, :code
      end
    end
  end
end
