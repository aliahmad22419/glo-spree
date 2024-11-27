module Spree
  module TaxCategoryDecorator
   def set_default_category
     # set existing default tax category to false if this one has been marked as default

     if is_default && tax_category = self.client.tax_categories.where(is_default: true).where.not(id: id).first
       tax_category.update_columns(is_default: false, updated_at: Time.current)
     end
   end
  end
end

::Spree::TaxCategory.prepend Spree::TaxCategoryDecorator if ::Spree::Store.included_modules.exclude?(Spree::TaxCategoryDecorator)
