class CreateSpreeBulkOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_bulk_orders do |t|
      t.references :user, null: false
      t.references :client, null: false
      t.string :state, null: false

      t.timestamps
    end
  end
end
