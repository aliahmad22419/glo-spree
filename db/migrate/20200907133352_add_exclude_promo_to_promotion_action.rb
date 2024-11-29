class AddExcludePromoToPromotionAction < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_promotion_actions, :exclude_sale_items, :boolean, default: false
  end
end
