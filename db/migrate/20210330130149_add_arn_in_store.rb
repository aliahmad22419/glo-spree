class AddArnInStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :acm_arn, :string, default: ""
  end
end
