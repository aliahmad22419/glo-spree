module Spree
	module OptionTypeDecorator
		def self.prepended(base)
			base.whitelisted_ransackable_attributes = ['presentation','name']
		end
	def destroy
		if products.present?
			errors.add(:option_type, "Can't delete with products")
			return false
		end
		super
	end
	end
end

::Spree::OptionType.prepend Spree::OptionTypeDecorator
