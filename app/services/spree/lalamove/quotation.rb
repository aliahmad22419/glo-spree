module Spree
	module Lalamove
		class Quotation
			prepend Spree::ServiceModule::Base
			include HTTParty

			def call(options:)
				run :quotation
			end

			private

			def quotation(options:)
				shipment = Spree::Shipment.find_by('spree_shipments.id = ?', options[:shipment_id])
				options[:scheduled_at] = (DateTime.now + 20.minutes).utc.iso8601 if options[:scheduled_at].blank?
				lalamove_service_type = shipment&.shipping_method&.lalamove_service_type
				order = shipment.order
				ship_from_address = shipment&.vendor&.ship_address
				ship_to_address = order&.ship_address
				store = order.store
				secret_key, public_key, market, url = [store.lalamove_sk, store.lalamove_pk, store.lalamove_market, store.lalamove_url]
				language= {'BR' => 'en_BR', 'HK' => 'en_HK', 'ID' => 'en_ID', 'MY' => 'en_MY', 'MX' => 'en_MX', 'PH' => 'en_PH', 'SG' => 'en_SG', 'TW'=> 'zh_TW', 'TH' => 'th_TH', 'VN'=> 'en_VN'}
				path = "/v3/quotations"
				method = "POST"
				body =%{
				{
					"data":{
									"scheduleAt": "#{options[:scheduled_at]}",
									"serviceType":"#{lalamove_service_type}",
									"language":"#{language[market]}",
									"stops":[
														{
															"address":"#{ship_from_address.full_address}"
														},
														{
															"address":"#{ship_to_address.full_address}"
														}
													]
									}
				}
			}
				time = DateTime.now.strftime('%Q')
				rawSignature= "#{time}\r\n#{method}\r\n#{path}\r\n\r\n#{body}"
				token = OpenSSL::HMAC.hexdigest('sha256', secret_key, rawSignature)
				token = "hmac #{public_key}:#{time}:#{token}"
				headers = {
						"Content-type": 'application/json; charset=utf-8',
						"Authorization": token,
						"Accept": 'application/json',
						"Market": market,
						"Request-ID": SecureRandom.uuid
				}
				response = HTTParty.post("#{url + path}", body: body, headers: headers)
				shipment.update_column(:lalamove_quotation_response, response.to_json)
				if response.code == 201
					return success(response)
				else
					return failure(response)
				end
			end
		end
	end
end
