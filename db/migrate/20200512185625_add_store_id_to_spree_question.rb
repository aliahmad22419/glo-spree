class AddStoreIdToSpreeQuestion < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_questions, :store_id, :integer
  end
end
