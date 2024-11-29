class AddLabelsToSpreeOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_orders, :labels, :jsonb, default: {}
  end
end
