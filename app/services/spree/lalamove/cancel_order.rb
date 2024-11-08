module Spree
	module Lalamove
		class CancelOrder
			prepend Spree::ServiceModule::Base
			include HTTParty

			def call(options:)
				run :cancel_order
			end

			private

			def cancel_order(options:)
				shipment = Spree::Shipment.find_by('spree_shipments.id = ?', options[:shipment_id])
				lalamove_order_id = JSON.parse(shipment.lalamove_order_response)["data"]["orderId"]
				order = shipment.order
				store = order.store
				secret_key, public_key, market, url = [store.lalamove_sk, store.lalamove_pk, store.lalamove_market, store.lalamove_url]

				path = "/v3/orders/" + lalamove_order_id
				method = "DELETE"
				body ='{"data": {}}'
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
				response = HTTParty.delete("#{url + path}", body: body, headers: headers)
				if response.code == 204
					shipment.update_column(:lalamove_order_response, '')
					shipment.update_column(:lalamove_quotation_response, '')
					return success(response)
				else
					return failure(response)
				end
			end
		end
	end
end
