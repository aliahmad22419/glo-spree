module Spree
	module StockItemDecorator
		def self.prepended(base)
			base.prepend Spree::Webhooks::HasWebhooks

			base.after_save :update_product_count_on_hand
			base.after_commit :sync_inventory_stock_items, if: -> { variant.linked_inventory.present? }
		end

		def update_product_count_on_hand
			product&.persist_count_on_hand
		end

		private
		def sync_inventory_stock_items
			variant.linked_inventory.update(quantity: self.count_on_hand)
		end
	end
end

::Spree::StockItem.prepend(Spree::StockItemDecorator)
