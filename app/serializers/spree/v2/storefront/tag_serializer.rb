module Spree
    module V2
      module Storefront
        class TagSerializer < BaseSerializer
          set_type :tag
  
          attributes :name
        end
      end
    end
  end
  