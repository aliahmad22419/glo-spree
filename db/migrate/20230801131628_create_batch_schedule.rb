class CreateBatchSchedule < ActiveRecord::Migration[5.2]
  def change
    create_table :batch_schedules do |t|
      t.date :start_date
      t.date :end_date
      t.integer :interval, default: 0 
      t.integer :step_count, default: 0
      t.text :week_days, array: true, default: [] #Sunday is represented by 0, Monday by 1, and so on.
      t.text :month_dates, array: true, default: []
      t.string :time_zone, default: "UTC", null: false

      t.references :schedulable, polymorphic: true, null: false
      t.timestamps
    end
  end
end
