class AddTruncatedTextLengthToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :truncated_text_length, :integer
  end
end
