module Spree
    class CreateTsgiftCard
        prepend Spree::ServiceModule::Base
        include HTTParty

        def initialize(params, client)
            @params = params
            @client = client
        end

        def create_card
            auth = {username: @client.ts_email, password: @client.ts_password}
            response = HTTParty.post(@client.ts_url + '/api/v1/gift_cards', body: @params, basic_auth: auth)
            return response
        end
    end
end
