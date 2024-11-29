class AddOneTimeReportAndStartEndDateToScheduledReport < ActiveRecord::Migration[6.1]
  def change
    add_column :scheduled_reports, :start_date, :date, null: true, default: nil
    add_column :scheduled_reports, :end_date, :date, null: true, default: nil
  end
end
