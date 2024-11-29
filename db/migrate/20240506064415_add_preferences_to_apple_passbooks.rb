class AddPreferencesToApplePassbooks < ActiveRecord::Migration[6.1]
  def change
    add_column :apple_passbooks, :preferences, :text
  end
end
