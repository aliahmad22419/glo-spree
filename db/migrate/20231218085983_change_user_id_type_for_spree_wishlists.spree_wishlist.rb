# This migration comes from spree_wishlist (originally 20210729053613)
class ChangeUserIdTypeForSpreeWishlists < ActiveRecord::Migration[4.2]
  def change
    change_table(:spree_wishlists) do |t|
      t.change :user_id, :bigint
    end
  end
end
