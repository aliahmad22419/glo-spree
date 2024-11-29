class AddRefundsTimelineToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :refunds_timeline, :integer, :default => 14
  end
end
