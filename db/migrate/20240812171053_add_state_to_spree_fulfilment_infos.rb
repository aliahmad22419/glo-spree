class AddStateToSpreeFulfilmentInfos < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_fulfilment_infos, :state, :integer, default: 0
  end
end
