module Spree
  module Api
    module V2
      module Storefront
        class ExchangeRatesController < ::Spree::Api::V2::BaseController
          require 'csv'
          before_action :require_spree_current_user, only: [:index, :create]
          before_action :set_currency, only: [:update]
          before_action :set_exchange_rate, only: [:update]
          before_action :check_permissions


          def index
            rates = current_client.present? ? current_client.currencies.with_out_vendor_currencies.order(:name) : Spree::Currency.with_out_vendor_currencies.order(:name)
            render_serialized_payload { serialize_collection(rates) }
          end

          def update
            if @exchange_rate.update(exchange_rate_params)
              render_serialized_payload { serialize_resource(@currency) }
            else
              render_error_payload(failure(@currency).error)
            end
          end

          def create
            csv_text = File.read(params[:file].path)
            csv = CSV.parse(csv_text, :headers => true)
            bulk_exchange_rates = []
            # Header values present in supported currencies
            currencies = current_client.supported_currencies.sort
            exchange_rate_table = csv.values_at(*currencies) # exchange rates matrix

            render json: { error: "Forbidden Entity" }, status: :unprocessable_entity and return if forbidden_tag_exist? exchange_rate_table.to_s

            # current_client.currencies.with_out_vendor_currencies.destroy_all
            ids = current_client.currencies.with_out_vendor_currencies.ids
            Spree::ExchangeRate.where(currency_id: ids).delete_all
            current_client.currencies.with_out_vendor_currencies.delete_all

            csv.by_col!
            first_column = csv.values_at(0).flatten.uniq # From currencies list
            first_column.each_with_index do |currency_name, currency_index|
              next if current_client.supported_currencies.exclude?(currency_name)

              currency = current_client.currencies.create(name: currency_name)
              exchange_rate_table[currency_index].each_with_index do |to_currency, index|
                bulk_exchange_rates << { currency_id: currency.id, name: currencies[index], value: exchange_rate_table[currency_index][index].to_f, created_at: Time.now, updated_at: Time.now }
              end
            end
            # set exchange rate zero for currencies supported by client but no exchage rate provided
            # it will cause zero price products
            not_in_file_currencies = current_client.supported_currencies - first_column
            not_in_file_currencies.each_with_index do |currency_name, currency_index|
              currency = current_client.currencies.with_out_vendor_currencies.find_or_create_by(name: currency_name)
              current_client.supported_currencies.each do |to_currency|
                bulk_exchange_rates << { currency_id: currency.id, name: to_currency, value: (currency.name.eql?(to_currency) ? 1 : 0.0), created_at: Time.now, updated_at: Time.now }
                # existing_currency = current_client.currencies.with_out_vendor_currencies.find_by(name: to_currency)
                # next if existing_currency.nil?
                
                # bulk_exchange_rates << { currency_id: existing_currency.id, name: currency.name, value: (currency.name.eql?(existing_currency.name) ? 1 : 0.0), created_at: Time.now, updated_at: Time.now}
              end
            end
            ::ClientCurrencyPricesWorker.perform_async(current_client.id,bulk_exchange_rates.uniq)

            render_serialized_payload { success({success: true}).value  }
          end

          private

          def valid_json?(json)
            begin
              JSON.parse(json)
              return true
            rescue Exception => e
              return false
            end
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::CurrencySerializer.new(collection).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::CurrencySerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_exchange_rate
            @exchange_rate = @currency.exchange_rates.find_by('spree_exchange_rates.id = ?', params[:id])
          end

          def set_currency
            currency_id = params[:exchange_rate][:currency_id] rescue nil
            @currency = if current_client.present?
              current_client.currencies.find_by('spree_currencies.id = ?', currency_id)
            else
              Spree::Currency.find_by('spree_currencies.id = ?', currency_id)
            end
          end

          def exchange_rate_params
            params.require(:exchange_rate).permit(:value)
          end

        end
      end
    end
  end
end
