module Iframe
    class Onboarding
        def call(store, client)
            ActiveRecord::Base.transaction do
                sub_client = create_sub_client(client, store)
                zone = create_zone(store, client)
                category = create_category(client)
                create_shipping_methods(store, client, category, zone)
                create_payment_method(store, client)
                vendor = create_vendor_user(store&.name, client)
                taxon = create_taxon(client)
                option_type = create_option_type(client)
                product = create_product(option_type, taxon&.id, store, client&.id, category&.id, vendor&.id)
                create_ts_credentials(store, client, product, sub_client)
            end
        end

        def create_store(store_name, client_id)
          store_default_url =((0...8).map { (65 + rand(26)).chr }.join.downcase)
          store = Spree::Store.create(client_id: client_id, name: store_name, code: store_name&.parameterize, mail_from_address: 'noreply@techsembly.com', default_url: store_default_url + "#{client_id}.techsembly.com", url: store_default_url + "#{client_id}.techsembly.com", country_ids: Spree::Country.ids, page_title: "#{store_name} Gift card | Shop Now", preferences: {store_type: "iframe", enable_customization_price: true, stripe_statement_descriptor_suffix: ''}, ses_emails: true, vendor_visibility: true, max_custom_price: 100000, custom_css: File.read(Rails.root.join('iframe_store_footer_css')))
          if store.present?
            create_ses_templates(store)
          end
        end

        private

        def create_sub_client(client, store)
            credentials = store&.name&.parameterize + client&.id.to_s + "-sub-user@techsembly.com"
            sub_client = client.users.new(name: "#{store&.name}-sub-client", email: credentials, password: credentials, allow_store_ids: [store&.id], is_enabled: true, state: "completed")
            sub_client.spree_roles = [Spree::Role.where(name: "sub_client").first]
            if sub_client.save
              assign_menu_items_to_sub_client(sub_client)
              sub_client.generate_spree_api_key!
            end
            return sub_client
        end

        def assign_menu_items_to_sub_client(sub_client)
          menu_items = MenuItem.permissible.parent_menus.items_with_role(['sub_client'])
          menu_items.each do |menu_item|
            MenuItemUser.create(menu_item_id: menu_item&.id, user_id: sub_client&.id, visible: true)
            sub_menu_items = MenuItem.where(parent_id: menu_item&.id).permissible.items_with_role(['sub_client'])
            sub_menu_items.map{|sub_menu_item| MenuItemUser.create(menu_item_id: sub_menu_item&.id, user_id: sub_client&.id, visible: (["TS Gifts Curate", "Settings"].include?(menu_item&.name) || ["Preview Product", "Product Trashbin"].include?(sub_menu_item&.name)) ? false : menu_item.visible)} if sub_menu_items.present?
          end
        end

        def create_zone(store, client)
            store.zones.create!(name: "Global", country_ids: Spree::Country.all.ids, client_id: client&.id)
        end

        def create_category(client)
            client.shipping_categories.create(name: "Gift Card Digital")
        end

        def create_shipping_methods(store, client, category, zone)
            store.shipping_methods.create!(
                [
                    {
                      client_id: client&.id, store_ids: [store&.id], zone_ids: [zone&.id], name: "TS Digital Fulfillment",
                        display_on: "both", admin_name: "TS Digital Fulfillment", shipping_category_ids: category.id,
                          calculator_type: "Spree::Calculator::Shipping::FlatRate", delivery_mode: "tsgift_digital",
                            visible_to_vendors: true
                    },
                    {
                      client_id: client&.id, store_ids: [store&.id], zone_ids: [zone&.id], name: "TS schedule fulfillment",
                        display_on: "both", admin_name: "TS Gift Card Digital Scheduled", shipping_category_ids: category.id,
                          calculator_type: "Spree::Calculator::Shipping::FlatRate", delivery_mode: "tsgift_digital",  
                            visible_to_vendors: true, scheduled_fulfilled: true, schedule_days_threshold: 365
                    }
                ]
                )
        end

        def create_payment_method(store, client)
          payment_methods = client.payment_methods.create!(
            [
              {
                type: "Spree::Gateway::StripeGateway", auto_capture: true, name: "Stripe Test", description: "Stripe Test",
                 payment_options: ["CreditCard"],
                  preferences: {
                    test_mode: true,
                    server: "test",
                    publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
                    client_key: ENV['STRIPE_CLIENT_KEY'],
                    secret_key: ENV['STRIPE_SECRET_KEY']
                  }
              },
              {
                type: "Spree::Gateway::StripeGateway", auto_capture: true, name: "Stripe Live", description: "Stripe Live",
                 payment_options: ["CreditCard"],
                  preferences: {
                    test_mode: false, server: "live"
                  }
              }
            ]
          )
          payment_method = payment_methods.select{|payment_method| payment_method.preferences[:test_mode]}.first
          store.store_payment_methods.create!(payment_method_id: payment_method&.id, payment_option: payment_method.payment_options[0], payment_option_display: payment_method.name)
        end

        def create_vendor_user(store_name, client)
            credentials = store_name&.parameterize + client.id.to_s + "@techsembly.com"
            vendor = client.vendors.create!(name: store_name, email: credentials, master: true, agreed_to_client_terms: true)
            user = Spree.user_class.new(email: credentials, password: credentials, state: "completed")
            user.spree_role_ids = Spree::Role.find_by_name("vendor").id
            user.save!
            vendor.users << user
            return vendor
        end

        def create_taxon(client)
            client.taxonomies.first.taxons.create!(name: 'Gift Card', parent_id: client.taxonomies.first.taxons.first.id, description: "Gift Card", meta_title: 'Gift Card', meta_description: 'Gift Card')
        end

        def create_option_type(client)
            option_type = client.option_types.create!(name: "Gift Card Design", presentation: "Gift Card Design", filterable: true)
            Spree::OptionValue.create!(
                    [
                        {
                            name: "Birthday Theme",
                            presentation: "Birthday Theme",
                            option_type_id: option_type.id
                        },
                        {
                            name: "Celebrate",
                            presentation: "Celebrate",
                            option_type_id: option_type.id
                        },
                        {
                            name: "Anniversary",
                            presentation: "Anniversary",
                            option_type_id: option_type.id
                        }
                    ]
                )

            return option_type
        end

        def create_ts_credentials(store, client, product, sub_client)
            store_name = store.name.split(" ").join("-")
            ts_client_user_email = "temp-iframe-client#{store.id}@techsembly.com"
            ts_api_user_email = "temp-iframe-api-user#{store.id}@techsembly.com"

            response = HTTParty.get(ENV['TS_GIFT_CARD_HOST'] + "/api/v1/clients/fast_track_record?store_name=#{store_name}&ts_client_user_email=#{ts_client_user_email}&ts_api_user_email=#{ts_api_user_email}")
            if response["success"]
                client.update_columns(ts_email: ts_client_user_email, ts_password: "123456", ts_url: ENV['TS_GIFT_CARD_HOST'])
                store.update_columns(ts_gift_card_email: ts_api_user_email, ts_gift_card_password: "123456", ts_gift_card_url: ENV['TS_GIFT_CARD_HOST'])
                ts_store = response["store"]
                create_ts_department(ts_store, client)
                create_ts_campaign(ts_store, client, product, sub_client)
                return ts_store
            end
        end

        def create_ts_department(store, client)
          department_params = {
            department: {
              department_name: "#{store['name']}-dept-#{store['id']}",
              department_description: "Department for iframe"
            }
          }
          response = HTTParty.post(ENV['TS_GIFT_CARD_HOST'] + "/api/v3/stores/#{store['id']}/departments", body: department_params, headers: {Authorization: basic_auth(client)})
          if JSON.parse(response.body)["id"]
            ts_department = JSON.parse(response.body)
            create_ts_front_desk_user(store, client, ts_department)
          end
        end

        def create_ts_front_desk_user(store, client, department)
          ts_redemption_user_email = "temp-redemption#{store['id']}@techsembly.com"
          user_params = {
            user: {
              name: "#{store['name']}-FD",
              email: ts_redemption_user_email,
              password: "123456",
              store_filter_id: store['id'],
              department_id: department['id'],
              menu_access: {top_up: true, activation: true, other_transaction: false},
              payment_methods: { cash: true, pos:false, credit_card: true }
            }
          }
          response = HTTParty.post(client.ts_url + "/api/v1/users", body: user_params, headers: {Authorization: basic_auth(client)})
          if JSON.parse(response.body)["id"]
            front_desk_user = client.users.new(email: ts_redemption_user_email, password: ts_redemption_user_email, name: "#{store['name']}-FD", is_v2_flow_enabled: true, state: "completed")
            front_desk_user.spree_roles = [Spree::Role.find_by(name: "front_desk")]
            front_desk_user.build_front_desk_credential(tsgifts_email: ts_redemption_user_email, tsgifts_password: "123456", tsgifts_url: client.ts_url)
            front_desk_user.save!
          end
        end

        def create_ts_campaign(store, client, product, sub_client)
          campaign_params = {
            campaign: {
              name: "Giftcard",
              code:"#{store['name']}-code-#{store['id']}",
              store_ids: [store['id']],
              email_subject: "Giftcard",
              email_html:"Giftcard",
              is_gift_card_remained_active: true,
              is_campaign_remained_active: true,
              allow_password: false,
              transaction_email_subject: "#{store['name']} gift card transaction",
              transaction_email_html: "#{store['name']} gift card transaction"
            }
          }
          response = HTTParty.post(client.ts_url + "/api/v1/campaigns", body: campaign_params, headers: {Authorization: basic_auth(client)})
          if JSON.parse(response.body)["id"]
            campaign_code = JSON.parse(response.body)["code"]
            product.update_column(:campaign_code, campaign_code)
            sub_client.update_column(:allow_campaign_ids, [JSON.parse(response.body)["id"]])
          end
        end

        def create_product(option_type, taxon_id, store, client_id, category_id, vendor_id)
            product = store.products.new(client_id: client_id, name: "p", shipping_category_id: category_id, taxon_ids: [taxon_id], selected_taxon_ids: [taxon_id], option_type_ids: [option_type.id], store_ids: [store.id], product_type: "gift", digital_service_provider: "tsgifts", delivery_mode: "tsgift_digital", ts_type: "monetary", send_gift_card_via: "email", voucher_email_image: "product_image", vendor_id: vendor_id, price: "0", available_on: DateTime.now, minimum_order_quantity: 1, default_quantity: 1)
            product.classifications.last.store_id = store.id
            product.save!
						product.activate
						variants = []
            option_type.option_values.each do |o_value|
                variant = product.variants.create!(option_value_ids: [o_value.id], sku: o_value.name, price: "0")
                variant.stock_items.first.update!(count_on_hand: 1000)
								variants << variant
            end
            create_variant_images(variants)
            custom_option = product.customizations.create!(field_type: "Drop-down", is_required: false, label: "Select gift card value", order: 1, store_ids: [store&.id])
						custom_option.customization_options.create!(label: "Customize (add additional amount to card)", sku: "SKU", price: "0")
						return product
        end

				def create_variant_images(variants)
					themes = ["birthday.png", "celebrate.png", "anniversary.png"]
					variants.each_with_index do |variant, index|
						img = Spree::Image.new(viewable_type: "Spree::Variant", viewable_id: variant&.id, attachment_file_name: themes[index], small_image: false, base_image: false, thumbnail: false, sort_order: index + 1, sort_order_info_product: index + 1)
						img.attachment.attach(io: File.open("#{Rails.root}/app/assets/images/#{themes[index]}"), filename: themes[0])
						img.save!
					end
				end

        def create_ses_templates(store)
					Spree::EmailTemplate.create(
                    [
                        {
                            name: "order_confirmation_customer_store_" + ENV['SES_ENV'] + "_" + store.id.to_s,
                            subject: "{{sender_name}}, We've Got Your Order {{order.number}}",
                            html: File.read(Rails.root.join('iframe_ses_email_templates/order-confirmation-customer.html')),
														email_type: "order_confirmation_customer",
														store_id: store&.id
                        },
                        {
													name: "regular_shipment_customer_store_" + ENV['SES_ENV'] + "_" + store.id.to_s,
													subject: "{{#if sender_name}}{{sender_name}}{{else}}{{from_name_first_name}} {{from_name_last_name}}{{/if}}, Good News, Your Order Has Been Shipped",
													html: File.read(Rails.root.join('iframe_ses_email_templates/shipped.html')),
													email_type: "regular_shipment_customer",
													store_id: store&.id
                        },
                        {
													name: "digital_ts_card_monetary_recipient_store_" + ENV['SES_ENV'] + "_" + store.id.to_s,
													subject: "You have received a {{store_name}} Gift Card!",
													html: File.read(Rails.root.join('iframe_ses_email_templates/monetary.html')),
													email_type: "digital_ts_card_monetary_recipient",
													store_id: store&.id
                        },
                        {
													name: "customer_password_reset_store_" + ENV['SES_ENV'] + "_" + store.id.to_s,
													subject: "Reset Password",
													html: File.read(Rails.root.join('iframe_ses_email_templates/forgot-password.html')),
													email_type: "customer_password_reset",
													store_id: store&.id
                        }
                    ]
                )
				end

        def basic_auth(client)
          "Basic #{Base64.strict_encode64("#{client.ts_email}:#{client.ts_password}")}"
        end
    end
end
