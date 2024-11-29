class AddSubFolderUrlsInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :allow_sub_folder_urls, :boolean, default: false
  end
end
