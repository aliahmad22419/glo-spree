class ChangeColumnsTypesToSaveWeights < ActiveRecord::Migration[5.2]
  def change
    change_column :spree_variants, :weight, :decimal, precision: 15, scale: 2
    change_column :spree_weights, :maximum, :decimal, precision: 15, scale: 2
    change_column :spree_weights, :minimum, :decimal, precision: 15, scale: 2
  end
end
