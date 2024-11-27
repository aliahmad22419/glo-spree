class ScheduledReport < ApplicationRecord
  include Spree::Preferences::Preferable
  # extend Archive
  serialize :preferences, Hash

  belongs_to :reportable, polymorphic: true

  enum scheduled_on: { once_day: 0, once_week: 1, once_month: 2, download_once: 3 }

  preference :fetch_from, :string, default: 'last_generated_at'
  preference :to_email_addresses, :array, default: []
  preference :cc_email_addresses, :array, default: []

  validate :ensure_update_validity, if: :persisted?
  validates :start_date, :end_date, presence: true, if: :download_once?

  before_save -> { self.start_date = self.end_date = nil }, unless: :download_once?
  after_commit :scheduled_report_cron_job, on: [:create, :update]
  after_destroy :delete_scheduled_report_cron_job

  SCHEDULED_SALES_REPORTS = ['sales_excluding_ppi','sales_including_ppi']
  SCHEDULED_TS_REPORTS = ['gift_cards_excluding_ppi','gift_cards_including_ppi','gift_cards_transactions','gift_cards_liability_excluding_ppi','gift_cards_liability_including_ppi']

  def client_obj
    self.reportable.class.eql?(Spree::Client) ? reportable : self.reportable.client
  end

  def self.add_to_zip filename, password
    Archive::Zip.archive(
      "#{filename}.zip", "#{filename}.csv",
      :encryption_codec => lambda do |entry|
        if entry.file? and entry.zip_path =~ /\.csv$/ then
          Archive::Zip::Codec::TraditionalEncryption
        else
          Archive::Zip::Codec::NullEncryption
        end
      end, password: password
    )
  end

  def scheduled_report_cron_job
    Sidekiq::Client.enqueue_to_in('scheduled_reports_queue', 1.hours, ScheduledReportsWorker, id) and return if download_once?

    Sidekiq::Cron::Job.destroy("#{saved_change_to_report_type.first}_#{id}") if saved_change_to_report_type&.[](0).present?
    job = Sidekiq::Cron::Job.find("#{report_type}_#{id}")
    job ||= Sidekiq::Cron::Job.new(
      name: "#{report_type}_#{id}",
      class: 'ScheduledReportsWorker',
      queue: 'scheduled_reports_queue',
      args: [id]
    )

    schedule_time = case scheduled_on
                    when 'once_day'
                      '59 23 * * *'
                    when 'once_week'
                      '59 23 * * SUN'
                    when 'once_month'
                      '59 23 28-31 * *'
                    end

    job.cron = "#{schedule_time} #{client_obj.timezone}"
    errors.add(:base, job.errors) unless job.save
  end

  def beginning_of_start_date
    start_date.beginning_of_day
  end

  def end_of_end_date
    end_date.end_of_day
  end

  private

  def delete_scheduled_report_cron_job
    if download_once?
      Sidekiq::ScheduledSet.new.each { |job| job.delete if job.args == [id] && job.queue == 'scheduled_reports_queue' }
    else
      Sidekiq::Cron::Job.destroy("#{report_type}_#{id}")
    end
  end

  def ensure_update_validity
    return unless scheduled_on_was.eql?(:download_once.to_s) && (download_once? || changes.present?)

    errors.add(:base, I18n.t("scheduled_report.once.in_future", updated_at: updated_at.strftime('%Y-%m-%d %H:%M'))) if (Time.now.utc - updated_at) < 24.hours
  end
end
