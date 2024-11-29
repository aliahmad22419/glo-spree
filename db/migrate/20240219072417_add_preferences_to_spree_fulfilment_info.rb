class AddPreferencesToSpreeFulfilmentInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_fulfilment_infos, :replacement_info, :json
    add_column :spree_fulfilment_infos, :info_type, :integer, default: 0
    add_column :spree_fulfilment_infos, :original_id, :integer, default: nil
    add_column :spree_fulfilment_infos, :each_card_value, :string
    add_reference :spree_fulfilment_infos, :replacement
  end
end
