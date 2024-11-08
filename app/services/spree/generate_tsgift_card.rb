module Spree
    class GenerateTsgiftCard
        prepend Spree::ServiceModule::Base
        include HTTParty

        def call(options:)
            run :generate_card
        end

        private

        def generate_card(options:)
            store = Spree::Store.find_by_id(store_id = options[:store_id])
            params = {gift_card: {
                value: options[:amount],
                product_name: options[:product_name],
                delivery_mode: options[:delivery_mode],
                recipient_first_name: options[:recipient_first_name],
                recipient_last_name: options[:recipient_last_name],
                recipient_email: options[:receipient_email],
                receipient_phone_number: options[:receipient_phone_number],
                order_number: options[:order_number],
                store_name: store.name,
                customer_email: options[:customer_email],
                bonus: options[:bonus],
                spree_ts_giftcard_id: options[:spree_ts_giftcard_id],
                order_placed_date: options[:order_placed_date],
                request_id: options[:request_id]
                },
                campaign_code: options[:campaign_code]
            }
            params[:gift_card][:currency] = options[:currency]
            params[:gift_card][:card_type] = (options[:card_type] == "monetary" ?  "monetary" : "experiences")
            params[:gift_card][:skus] = options[:skus] if options[:card_type] == "experiences"
            params[:gift_card][:shipping_address_attributes] = options[:shipping_address] if options[:shipping_address].present?
            auth = {username: store.ts_gift_card_email, password: store.ts_gift_card_password}
            response = HTTParty.post(store.ts_gift_card_url.to_s + '/api/v1/gift_cards', body: params, basic_auth: auth)
            success(response)
        end
    end
end
