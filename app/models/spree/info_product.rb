module Spree
	class InfoProduct < Spree::Base
		belongs_to :product, :class_name => 'Spree::Product'
		enum media_type: { video: 0, image: 1, embed: 2 }
	end
end