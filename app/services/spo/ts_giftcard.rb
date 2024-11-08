module Spo
  class TsGiftcard

    def initialize(store,credential=nil)
      @store = store
      @ts_credential = ts_credential(credential)
    end

    #topup_options must have amount, currency, number and notes, store_id
    def topup(card_params)
      path = "/api/v3/gift_cards/transaction"
      transaction(path, topup_params(card_params))
    end

    def activation(card_params)
      path = "/api/v3/gift_cards/activation"
      transaction(path, activation_params(card_params))
    end

    def send_emails(emails_params)
      path = "/api/v3/gift_cards/send_email"
      transaction_put(path, emails_params)
    end


    private

    def topup_params(card_params)
      {
        "type": "monetary",
        "transaction_reason": "TopUp",
        "number": card_params[:number],
        "notes": card_params[:notes],
        "currency": card_params[:currency],
        "amount": card_params[:amount],
        "store_id": card_params[:store_id],
        "allow_transaction_fee": card_params[:allow_transaction_fee],
        "payment_method": card_params[:ts_payment_method],
        "external_invoice_id": card_params[:external_invoice_id],
        "meta": card_params[:meta],
        "operator_id": card_params[:operator_id],
        "pin": card_params[:pin],
        "creator_attributes": card_params[:creator_attributes]
      }
    end

    def activation_params(card_params)
      card_params["gift_card"]["store_name"] = card_params["store_name"]
      card_params
    end

    def ts_credential(credential)
      client = @store.client
      { ts_url: client.ts_url, ts_email: credential ? credential["ts_email"] : client.ts_email, ts_password: credential ? Base64.decode64(credential["ts_password"]) : client.ts_password }
    end

    def transaction(path, body)
      HTTParty.post(@ts_credential[:ts_url] + path, body: body, headers: { Authorization: basic_auth })
    end

    def transaction_put(path, body)
      HTTParty.put(@ts_credential[:ts_url] + path, body: body, headers: { Authorization: basic_auth })
    end

    def basic_auth
      "Basic #{Base64.strict_encode64("#{@ts_credential[:ts_email]}:#{@ts_credential[:ts_password]}")}"
    end
  end
end
