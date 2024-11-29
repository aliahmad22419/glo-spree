class AddSpoInvoiceToSpreeOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :spo_invoice, :string
  end
end
