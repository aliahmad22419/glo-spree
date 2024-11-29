class AddTimestampInTscards < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_ts_giftcards, :created_at, :datetime
    add_column :spree_ts_giftcards, :updated_at, :datetime
  end
end
