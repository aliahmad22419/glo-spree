module Spree
	module CalculatorDecorator
		def self.prepended(base)
			base.after_save :update_preferences
		end
		# after_update :set_currency_to_empty_on_update

		def set_currency_to_empty_on_update
			update_preferences if type_changed?
		end

		def update_preferences
			if preferences[:currency].present?
				preferences[:currency] = ''
				self.save
			end
		end
	end
end

Spree::Calculator.prepend Spree::CalculatorDecorator
