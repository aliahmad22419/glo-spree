module Spree
	module Admin
		module ProductsControllerDecorator
 			def self.prepended(base)
				# base.update.before :set_stores
			end

			private

			def set_stores
				# @product.store_ids = nil unless params[:product].key? :store_ids
			end

			def find_stores
				# store_ids = params[:product][:store_ids]
				# if store_ids.present?
				# 	params[:product][:store_ids] = store_ids.split(',')
				# end
			end
		end
	end
end

::Spree::Admin::ProductsController.prepend Spree::Admin::ProductsControllerDecorator
