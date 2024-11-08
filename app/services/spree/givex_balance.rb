module Spree
  class GivexBalance
    prepend Spree::ServiceModule::Base
    include Spree::RequestGivex
    include HTTParty

    def call(options:, store:)
      run :check_balance
    end

    private

    def check_balance(options:, store:)
      store_code = store.code.upcase
      body = {
          "jsonrpc": "2.0",
          "method": "994",
          "id": 4377,
          "params": [store.supported_locale, "", store.givex_user, store.givex_password, options[:card_number], options[:card_pin], ""]
      }.to_json

      response = handle_request(store.givex_url, body, store.givex_secondary_url)
      return failure(response.message) unless response.success?

      data = if response["result"].present? && response["result"].count < 4
                response["result"][2] == "Cert not exist" ? "Certificate does not exist" : response["result"][2]
              else
                bal  = response["result"][2]
                currency = response["result"][5]
                date = response["result"][4]
                iso_serial = response["result"][10]
                {balance: bal.to_s, currency: currency.to_s, expiry: date.to_s,iso_serial: iso_serial}
              end
      success(data)
    rescue => exception
      failure(exception.message)
    end

  end
end
