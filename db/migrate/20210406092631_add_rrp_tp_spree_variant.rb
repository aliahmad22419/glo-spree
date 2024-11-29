class AddRrpTpSpreeVariant < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_variants, :rrp, :float
  end
end
