module Spree
  module ShippingCategory
    def self.prepended(base)
      base.before_destroy :check_linked_products
    end

    def check_linked_products
      if products.exists?
        errors.add(:base, 'A product is linked to this shipping category.')
        throw(:abort)
      end
    end
  end
end

::Spree::ShippingCategory.prepend(Spree::ShippingCategoryDecorator)
