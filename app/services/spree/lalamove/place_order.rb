module Spree
	module Lalamove
		class PlaceOrder
			prepend Spree::ServiceModule::Base
			include HTTParty

			def call(options:)
				run :place_order
			end

			private

			def place_order(options:)
				shipment = Spree::Shipment.find_by('spree_shipments.id = ?', options[:shipment_id])
				quotation = JSON.parse(shipment.lalamove_quotation_response)["data"]
				remarks = options[:remarks].to_s
				vendor = shipment.vendor
				order = shipment.order
				ship_to_address = order&.ship_address
				store = order.store
				secret_key, public_key, market, url = [store.lalamove_sk, store.lalamove_pk, store.lalamove_market, store.lalamove_url]

				path = "/v3/orders"
				method = "POST"
				body =%{
				{
					"data": {
							"quotationId": "#{quotation["quotationId"]}",
							"sender": {
									"stopId": "#{quotation["stops"][0]["stopId"]}",
									"name": "#{vendor.name}",
									"phone": "#{vendor.phone&.strip.to_s}"
							},
							"recipients": [
									{
											"stopId": "#{quotation["stops"][1]["stopId"]}",
											"name": "#{ship_to_address.firstname + ' ' + ship_to_address.lastname}",
											"phone": "#{ship_to_address.phone&.strip.to_s}",
											"remarks": "#{remarks}"
            			}
        			],
							"isRecipientSMSEnabled": true,
							"partner": "Partner Techsembly",
							"metadata": {
									"restaurantOrderId": "#{order.number}",
									"restaurantName": "#{store.name}"
							}
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
				shipment.update_column(:lalamove_order_response, response.to_json)
				if response.code == 201
					shipment.update_column(:lalamove_order_id, response["data"]["orderId"])
					return success(response)
				else
					return failure(response)
				end
			end
		end
	end
end
