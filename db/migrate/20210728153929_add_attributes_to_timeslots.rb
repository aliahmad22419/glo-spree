class AddAttributesToTimeslots < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_time_slots, :start_time, :string
    add_column :spree_time_slots, :end_time, :string
  end
end
