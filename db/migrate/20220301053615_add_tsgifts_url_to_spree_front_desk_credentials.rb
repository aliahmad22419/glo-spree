class AddTsgiftsUrlToSpreeFrontDeskCredentials < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_front_desk_credentials, :tsgifts_url, :string
  end
end
