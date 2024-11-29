class CreateWeights < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_weights do |t|
      t.float :maximum, default: 0
      t.float :minimum, default: 0
      t.float :price, default: 0
      t.references :weightable, polymorphic: true
      t.timestamps
    end
  end
end
