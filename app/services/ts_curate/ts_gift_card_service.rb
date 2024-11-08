module TsCurate
  class TsGiftCardService
    attr_accessor :params, :store, :options, :ts_card, :current_user, :auth, :ts_url

    def initialize(card, params, options = {})
      @ts_card = card
      @params = params
      @store = @ts_card.store
      @options = options
    end

    def cancel_card
      retrieve_cancel_data

      result = HTTParty.put("#{ts_url}/api/v3/gift_cards/#{@cancel_card_params[:gift_card][:id]}", body: @cancel_card_params, basic_auth: auth)

      if result['status'] == 'canceled'
        history_logs = create_history_log
        ts_card.update_columns(status: 'canceled', updated_at: Time.now.utc)
        {success: true, card_status: 'canceled', history_logs: history_logs}
      else
        {success: false, error: I18n.t('spree.ts_card.not_cancel')}
      end
    end


    private

    def create_history_log
      ts_card.history_logs.create(
          kind: 'card_cancellation',
          history_notes: params[:notes],
          creator_email: current_user.email,
          platform: 'cs-dashboard',
          creator_id: current_user.id)
    end

    def retrieve_cancel_data
      @current_user = options[:spree_current_user]
      ts_response = JSON.parse(ts_card.response)
      client = store.client
      @auth = {username: client.ts_email, password: client.ts_password}
      @ts_url = client.ts_url

      @cancel_card_params = {
          gift_card: {
              id: ts_response.dig('value', 'id'),
              status: 'canceled',
              store_id: ts_response.dig('value', 'initial_store_id'),
              transitions_attributes: [
                  {transition_state_name: 'status',
                   notes: params[:notes],
                   pervious_state: ts_response.dig('value', 'status'),
                   current_state: 'canceled',
                   creator_attributes: {
                       creator_email: current_user.email,
                       creator_role: 'customer_support'
                   }
                  }
              ]
          }
      }
    end
  end
end
