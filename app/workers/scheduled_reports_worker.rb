class ScheduledReportsWorker
  include Sidekiq::Worker
  include Sidekiq::Worker::ClassMethods
  sidekiq_options queue: 'scheduled_reports_queue'

  def perform(scheduled_report_id)
    report = ScheduledReport.find(scheduled_report_id)

    # check month's end between 28-31 dates (for monthly scheduled reports)
    datetime = Time.now.in_time_zone(report.client_obj.timezone)
    return if report.once_month? && datetime.day != datetime.end_of_month.day

    Spree::Scheduled::ReportGenerator.new(scheduled_report_id).generate
  end
end
