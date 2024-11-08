module Spree
  class GivexApi
    prepend Spree::ServiceModule::Base
    include Spree::RequestGivex
    attr_accessor :params, :store, :options, :current_user, :card, :cancellation_notes

    def initialize(params, store, options = {})
      @params = params
      @store = store
      @options = options
    end

    def givex_api
      @params[:params] = ["en", "1", @store.givex_user, @store.givex_password] + @params[:params]
      response = handle_request(store.givex_url, @params.to_json, store.givex_secondary_url)
      response.success? ? success(response) : failure(response.message)
    rescue => exception
      failure(exception.message)
    end

    def cancel_givex_api
      retrieve_cancel_data

      response = givex_api
      # result = response.value['result'] || []
      result = response.dig('value', 'result') || []

      if response.success && result[1].to_i.zero? #result code 0 means Success
        history_log = create_history_log
        card.update_columns(status: 'canceled', updated_at: Time.now.utc)
        { success: true, card_status: 'canceled', history_logs: history_log }
      else
        { success: false, error: result[2] || response.value }
      end
    end

    private
    def retrieve_cancel_data
      @card = options[:card]
      @current_user = options[:current_user]
      @cancellation_notes = params[:notes]

      @params = {
          "jsonrpc": "2.0",
          "method": "907",
          "id": "5339826",
          "params": [card.givex_number, card.balance.to_f.to_s]
      }
    end

    def create_history_log
      card.history_logs.create(
          kind: 'card cancellation',
          history_notes: cancellation_notes,
          creator_email: current_user.email,
          platform: 'cs-dashboard',
          creator_id: current_user.id,
          meta: {givex_info_id: '5339826'}
      )
    end
  end
end
