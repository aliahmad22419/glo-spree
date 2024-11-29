class AddDownloadOrderDetailsToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :download_order_details, :boolean, default: false
  end
end
