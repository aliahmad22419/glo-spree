class AddStateToSpreeRefunds < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_refunds, :state, :integer, default: 0
  end
end
