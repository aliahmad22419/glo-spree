module Spree::PropertyDecorator
	def self.prepended(base)
		base.has_and_belongs_to_many :stores, class_name: 'Spree::Store'
		base.whitelisted_ransackable_attributes = ['presentation','name']
		base.before_destroy :destroy_translations, prepend: true
	end

	def destroy_translations
		product_properties.each do |product_property|
			product_property.translations.destroy_all
		end
	end
end

::Spree::Property.prepend(Spree::PropertyDecorator) unless ::Spree::Property.ancestors.include?(Spree::PropertyDecorator)
