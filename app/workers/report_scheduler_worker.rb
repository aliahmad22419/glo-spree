class ReportSchedulerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'report_scheduler'

  def perform()
    Spree::Store.ids.each do |store_id|
      FacebookFeedWorker.perform_async(store_id)
      LystFeedWorker.perform_async(store_id)
      ReviewsIoFeedWorker.perform_async(store_id)
    end
  end
end
