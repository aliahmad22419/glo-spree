class CreateOrderTags < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_order_tags do |t|
      t.integer :client_id
      t.string :label_name
      t.string :intimation_email
      t.timestamps
    end
  end
end
