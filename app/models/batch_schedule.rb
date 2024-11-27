class BatchSchedule < ApplicationRecord
  belongs_to :schedulable, polymorphic: true

  enum interval: { daily: 0, weekly: 1, monthly: 2 }

  before_validation :validate_dates
  validates :start_date, :end_date, presence: true
  validates :week_days, length: { minimum: 1, maximum: 7, message: "Please select week days between 1 to 7" }, if: :weekly?
  validates :month_dates, length: { minimum: 1, maximum: 31, message: "Please select month dates between 1 to 31" }, if: :monthly?
  validates :step_count, numericality: { greater_than: 0 }
  validates :time_zone, inclusion: { in: TZInfo::Timezone.all_identifiers }

  def batch_count
    send("#{interval}_batch_dates").count
  end

  def effective_dates
    send("#{interval}_batch_dates").map { |date| date.in_time_zone(time_zone) }
  end

  private
  def validate_dates
    return unless start_date && end_date

    if end_date < start_date
      errors.add(:end_date, I18n.t('batch_schedule.greater_end_date'))
    elsif start_to_end_days > 365
      errors.add(:end_date, I18n.t('batch_schedule.smaller_end_date'))
    end
  end

  def daily_batch_dates
    (start_date..end_date).step(step_count).to_a
  end

  def weekly_batch_dates
    dates = []
    current_date = start_date
    current_week = current_date.cweek

    while current_date <= end_date
      dates.push current_date if week_days.include? current_date.wday.to_s
      current_date = current_date.next
      if current_date.cweek != current_week
        current_date += (step_count-1).weeks 
        current_week = current_date.cweek
      end
    end
    dates
  end
  
  def monthly_batch_dates
    dates = []
    current_date = start_date
    current_month = current_date.month

    while current_date <= end_date
      dates.push current_date if month_dates.include? current_date.day.to_s
      current_date = current_date.next
      if current_date.month != current_month
        current_date += (step_count-1).months 
        current_month = current_date.month
      end
    end
    dates
  end

  def start_to_end_days
    (self.start_date..self.end_date).count
  end

end