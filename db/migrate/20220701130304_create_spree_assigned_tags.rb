class CreateSpreeAssignedTags < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_assigned_tags do |t|
      t.references :product
      t.references :product_tag
      t.timestamps
    end
  end
end
