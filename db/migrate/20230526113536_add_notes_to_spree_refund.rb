class AddNotesToSpreeRefund < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_refunds, :notes, :text
    add_column :spree_refunds, :user_id, :integer
    add_column :spree_refunds, :order_id, :integer
  end
end
