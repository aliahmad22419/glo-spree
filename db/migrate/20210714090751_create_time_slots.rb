class CreateTimeSlots < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_time_slots do |t|
      t.float :interval
      t.integer :shipping_method_id
      t.timestamps
    end
  end
end
