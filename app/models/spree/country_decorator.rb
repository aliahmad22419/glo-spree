module Spree
	module CountryDecorator
		def self.prepended(base)
			base.has_and_belongs_to_many :stores, class_name: 'Spree::Store'
		end
	end
end

::Spree::Country.prepend(Spree::CountryDecorator) unless ::Spree::Country.ancestors.include?(Spree::CountryDecorator)
