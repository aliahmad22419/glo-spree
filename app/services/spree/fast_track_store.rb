module Spree
    class FastTrackStore

        def call(store)
            ActiveRecord::Base.transaction do
                layout_setting = Spree::LayoutSetting.create(store_id: store.id)
                layout_setting.preferences[:custom_js_links] = [{"id"=>"global", "name"=>"global", "url"=>ENV['CUSTOM_JS']}]
                layout_setting.preferences[:custom_css] = File.read(Rails.root.join('custom_css'))
                layout_setting.save
                payment_method = store.payment_methods.create!(type: "Spree::Gateway::StripeGateway", auto_capture: true, name: "Stripe Test", description: "Stripe Test", payment_options: ["CreditCard"], client_id: store&.client&.id, preferences: {publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'], client_key: ENV['STRIPE_CLIENT_KEY'], secret_key: ENV['STRIPE_SECRET_KEY'], test_mode: true, server: "test"})
                store.checkout_flow = 'v3'
                store.enable_v3_billing = true
                store.save!
                payment_method.store_payment_methods.last.update(payment_option: payment_method.payment_options[0], payment_option_display: payment_method.name)
                zone = store.zones.create!(name: "Global", country_ids: Spree::Country.all.ids, client_id: store&.client&.id)
                store.client.shipping_methods.create!(store_ids: [store&.id], zone_ids: [zone&.id], name: "TS Gift Card Digital", display_on: "both", admin_name: "TS Gift Card Digital", shipping_category_ids: store.client.shipping_category_ids, calculator_type: "Spree::Calculator::Shipping::FlatRate", delivery_mode: "tsgift_digital", visible_to_vendors: true)
                store.client.shipping_methods.first.update!(zone_ids: [zone&.id])
                store.client.taxonomies.first.taxons.create!(name: 'gift-card', parent_id: store.client.taxonomies.first.taxons.first.id, description: "gift-card", meta_title: 'gift-card', meta_description: 'gift-card')
    
                store_name = store.name.split(" ").join("-")
                ts_client_user_email = "#{store_name}-client-#{store.id}@example.com"
                ts_api_user_email = "#{store_name}-api-user-#{store.id}@example.com"
    
                response = HTTParty.get(ENV['TS_GIFT_CARD_HOST'] + "/api/v1/clients/fast_track_record?store_name=#{store.name}&ts_client_user_email=#{ts_client_user_email}&ts_api_user_email=#{ts_api_user_email}")
                if response["success"]
                    store.client.update_columns(ts_email: ts_client_user_email, ts_password: "123456", ts_url: ENV['TS_GIFT_CARD_HOST'])
                    store.update_columns(ts_gift_card_email: ts_api_user_email, ts_gift_card_password: "123456", ts_gift_card_url: ENV['TS_GIFT_CARD_HOST'])
                end
            end
        end
    end
end