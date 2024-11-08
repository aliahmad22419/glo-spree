
# RMB is not supported so we will have to use CNH for chinese currency.
class AutoExchangeRatesWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'auto_exchange_rates'

  def perform
    today = Date.today
    
    Spree::Client.find_each do |client|
      next unless client.preferred_enable_auto_exchange_rates
      schedule = client.preferred_exchange_rates_schedule   
      
      next if schedule.eql?('once_week') && !today.monday?
      next if schedule.eql?('once_month') && today.day != 1

      supported_currencies = client.currencies.with_out_vendor_currencies
      supported_currencies.each do |from_currency|
        from = from_currency.name
        from = 'CNH' if from.eql?('RMB') # replace RMB with CNH
        
        supported_currencies.each do |to_currency|
          to = to_currency.name
          to = 'CNH' if to.eql?('RMB') # replace RMB with CNH

          begin
            url = "#{ENV['OANDA_PROXY_SERVER']}?from=#{from}&to=#{to}"
            response = JSON.parse(HTTParty.get(url))

            if response["quotes"].present?
              exchange_rate = from_currency.exchange_rates.find_or_initialize_by(name: to)
              exchange_rate.update(value: response["quotes"]["#{to}"]["midpoint"].to_f)
            end

          rescue => exception
            Rails.logger.error("#{exception}")
          end

        end

      end

      client.preferred_exchange_rates_updated_at = Date.today.to_s
      client.save
    end

  end
end
