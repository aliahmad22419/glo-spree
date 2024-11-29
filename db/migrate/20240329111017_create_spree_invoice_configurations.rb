class CreateSpreeInvoiceConfigurations < ActiveRecord::Migration[6.1]
  def change
    create_table :spree_invoice_configurations do |t|
      t.string :brand
      t.text :address
      t.string :phone
      t.string :email
      t.text :notes
      t.text :preferences
      t.references :store, null: false, index: true
    end
  end
end
