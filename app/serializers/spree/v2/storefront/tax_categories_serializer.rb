module Spree
  module V2
    module Storefront
      class TaxCategoriesSerializer < BaseSerializer
        set_type  :tax_categories

        attribute :id, :name, :description, :is_default, :tax_code
      end
    end
  end
end
