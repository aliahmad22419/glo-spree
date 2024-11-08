class ScheduleSalesReportsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'schedule_sales_reports'

  def perform
    today = Date.today
    Spree::Store.where(enable_finance_report: true).find_each do |store|
      next if store.every_storefront_sale?
      next if store.once_week? && !today.sunday?
      next if store.once_month? && today.day != 1
      FinanceReportWorker.perform_async(store.id)
    end
  end
end
