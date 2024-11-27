
module Spree
  module ProductPropertyDecorator
    def self.prepended(base)
      base.after_commit -> (obj) { obj.product.reindex }, if: :saved_change_to_value?
    end

    def property_name=(name)
      if name.present?
        # don't use `find_by :name` to workaround globalize/globalize#423 bug
        self.property = Spree::Property.where(name: name).first_or_create(presentation: name)
      end
    end

  end
end
::Spree::ProductProperty.prepend Spree::ProductPropertyDecorator
