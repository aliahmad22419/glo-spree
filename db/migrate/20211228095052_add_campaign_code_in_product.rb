class AddCampaignCodeInProduct < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :campaign_code, :string, default: ''
  end
end
