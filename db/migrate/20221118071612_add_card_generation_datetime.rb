class AddCardGenerationDatetime < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_shipments, :card_generation_datetime, :datetime
  end
end
