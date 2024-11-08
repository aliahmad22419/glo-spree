class UpdateSupportedCurrencyExchangesWorker < CurrencyPriceWorker
	include Sidekiq::Worker
	sidekiq_options queue: 'update_currency_price', retry: 3

	def perform(client_id, options)
		current_client = Spree::Client.find_by_id client_id
		return unless current_client.present?

		Searchkick.callbacks(:bulk) do
			# Create exchanges for newly added supported currencies
			options["supported_currencies"].each { |currency| current_client.send(:set_default_exchange_rate, currency) }
			
			# remove non supported currency and exchanges
			current_client.currencies.with_out_vendor_currencies.where.not(name: current_client.supported_currencies).destroy_all
			current_client.currencies.with_out_vendor_currencies.where(name: current_client.supported_currencies).each do |currency|
				currency.exchange_rates.where.not(name: current_client.supported_currencies).destroy_all
			end

			Spree::ProductCurrencyPrice
				.where("product_id IN (?) AND to_currency NOT IN (?)", options["ids"], current_client.supported_currencies)
				.destroy_all

			#create exchange rate values for newly added supported currencies
			if options["supported_currencies"].present? && options["ids"].present?
				options["ids"].each { |product_id| update_prices(product_id, { "currency" => options["supported_currencies"] }) }
			end
		end
	end
end
