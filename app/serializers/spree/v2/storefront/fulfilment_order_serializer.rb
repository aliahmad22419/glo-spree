module Spree
  module V2
    module Storefront
      class FulfilmentOrderSerializer < BaseSerializer
        set_type :order

        attributes :number, :email, :total, :currency

        attribute :zone do |order|
          order&.zone&.name
        end

        attribute :total do |order|
          order.price_values(order.currency)[:prices]
        end

        attribute :store_name do |order|
          order&.store&.name
        end

        attribute :order_status do |order|
          state = order.shipments.where("delivery_mode = ? OR delivery_mode = ?", "givex_physical", "tsgift_physical")&.map(&:fulfilment_status)
          if state&.include?("pending")
            "pending"
          elsif state&.include?("processing")
            "processing"
          elsif state&.include?("fulfiled")
            "fulfilled"
          end
        end

        attribute :shipment_states do |order|
          order&.shipments.physical.map(&:fulfilment_status)
        end

        attributes :address do |order|
          address = order&.shipping_address
          [
            address&.address1,address&.address2,address&.apartment_no,address&.city,address&.country&.name,address&.district,
            address&.firstname,address&.lastname,address&.phone,address&.region,address&.state_name,address&.zipcode
          ].compact!&.join(',')
        end

        attribute :currency_symbol do |object|
          Spree::Money.new(object.currency).currency.symbol
        end

      end
    end
  end
end
