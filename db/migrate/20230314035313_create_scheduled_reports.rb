class CreateScheduledReports < ActiveRecord::Migration[5.2]
  def change
    create_table :scheduled_reports do |t|
      t.string :report_type
      t.integer :scheduled_on, default: 0
      t.string :password
      t.text :store_ids, default: [], array: true
      t.text :ts_store_ids, default: [], array: true
      t.string :reportable_type
      t.bigint :reportable_id
      t.text :preferences
      t.text :report_link
      t.datetime :report_link_updated_at
      t.index ["reportable_type", "reportable_id"], name: "index_scheduled_reports_on_reportable_type_and_reportable_id"

      t.timestamps
    end
  end
end
