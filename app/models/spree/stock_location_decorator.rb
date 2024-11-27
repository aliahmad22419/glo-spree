module Spree
	module StockLocationDecorator
		def self.prepended(base)
			base.clear_validators!
			base.validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :vendor_id }
		end
	end
end

::Spree::StockLocation.prepend(Spree::StockLocationDecorator)
