module Spree
  class RegisterGivex
    prepend Spree::ServiceModule::Base
    include Spree::RequestGivex
    include HTTParty

    def call(options:)
      run :register_to_givex
    end

    private

    def register_to_givex(options:)
      store = Spree::Store.find_by_id(store_id = options[:store_id])
      body = {
          "jsonrpc": "2.0",
          "method": "904",
          "id": options[:id],
          "params": [store.supported_locale, options[:id], store.givex_user, store.givex_password, options[:amount], "", options[:comments] || "", ""]
      }.to_json

      response = handle_request(store.givex_url, body, store.givex_secondary_url)
      return failure(response.message) unless response.success?

      success(response)
    rescue => exception
      failure(exception.message)
    end

  end
end
