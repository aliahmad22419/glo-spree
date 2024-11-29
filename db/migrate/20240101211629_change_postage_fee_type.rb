class ChangePostageFeeType < ActiveRecord::Migration[5.2]
  def up
    change_column :spree_fulfilment_infos, :postage_fee, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :spree_fulfilment_infos, :postage_fee, :bigint
  end
end
