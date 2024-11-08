module Spree
    class RegisterHawk
        prepend Spree::ServiceModule::Base
        include HTTParty

        def call(options:)
            run :register_hawk
        end

        private

        def register_hawk(options:)
            store = Spree::Store.find_by_id(store_id = options[:store_id])
            auth = {:username => store&.hawk_username, :password => store&.hawk_password}

            transaction_code = get_transaction_code
            headers = {
                "Content-Type": "application/json"
            }

            if options[:delivery_mode] == "blackhawk_digital"
                body = {
                    "StoreChannelCode": store&.hawk_store_channel_code,
                    "ApiAlias": "testAPi",
                    "IsNotifiedByEmail": true,
                    "Recipient": {
                        "Email": options[:customer_email],
                        "FirstName": options[:customer_first_name]
                    },
                    "IsPhysicalDispatchment": "false",
                    "StoreCards": options[:store_cards_arr],
                    "TransactionCode": transaction_code
                }
            else
                order = Spree::Order.find_by_id(options[:order_id])
                ship_address = order&.ship_address
                body = {
                    "StoreChannelCode": store&.hawk_store_channel_code,
                    "ApiAlias": "testAPi",
                    "IsNotifiedByEmail": true,
                    "Recipient": {
                        "Email": order&.email,
                        "FirstName": order&.name
                    },
                    "IsPhysicalDispatchment": "true",
                    "ShippingInfo": {
                        "SpecialRequest": "sample string 1",
                        "BillingAddress": {
                            "Country": ship_address&.country&.name,
                            "Postcode": ship_address&.zipcode,
                            "PhoneNumber": ship_address&.phone,
                            "State": ship_address&.state_name,
                            "AddressLine1": ship_address&.address1,
                            "AddressLine2": ship_address&.address2,
                            "Suburb": ship_address&.address2
                        }
                    },
                    "StoreCards": options[:store_cards_arr],
                    "TransactionCode": transaction_code
                }
            end

            response = HTTParty.post("#{store&.hawk_api_url}/storecards/allocate", body: body.to_json, headers: headers, basic_auth: auth)
            success(response)
        end

        def get_transaction_code
            rand(42**8).to_s(36)
        end
    end
end
