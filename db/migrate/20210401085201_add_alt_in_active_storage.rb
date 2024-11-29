class AddAltInActiveStorage < ActiveRecord::Migration[5.2]
  def change
    add_column :active_storage_attachments, :alt, :text
  end
end
