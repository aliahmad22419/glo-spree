class AddPreferencesToSpreePromotionAction < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_promotion_actions, :preferences, :text
  end
end
