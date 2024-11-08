module Spree
  module V2
    module Storefront
      class FulfilmentInfoSerializer < BaseSerializer
        set_type :fulfilment_info

        attributes  :id, :serial_number, :currency, :customer_shippment_paid, :processed_date, :postage_currency, :info_type,
                  :postage_fee, :receipt_reference, :courier_company, :tracking_number, :comment, :accurate_submition, :shipment_id

        attribute :gift_card_number do |object,params|
          gift_card = object&.gift_card_number

          if params[:current_user].has_spree_role?("fulfilment_admin") || (params[:current_user].has_spree_role?("fulfilment_user") && object.shipment.fulfilment_status != 'processing')
            gift_card = gift_card.split(',').map{|gift_card| 
              gift_card.length >= 6 ? gift_card&.gsub(/.(?=.{4})/, '*') : gift_card&.gsub(/.(?=.{2})/, '*')
            }.join(',')
          end
          gift_card
        end

        attribute :replacements do |object|
          object.replacements&.sorted_infos
        end

        attribute :replaced do |object|
          object.replacements&.first&.replacement_fulfiled?
        end

        attribute :user do |object|
          { name: object.user&.name }
        end

        attribute :shipment do |object|
          {
            delivery_mode: object.shipment&.delivery_mode,
            fulfilment_status: object.shipment&.fulfilment_status,
            order: {
              id: object.shipment&.order&.id,
              completed_at: object.shipment&.order&.completed_at,
              number: object.shipment&.order&.number,
              email: object.shipment&.order&.email,
              currency: object.shipment&.order&.currency,
              zone: { name: object.shipment&.order&.zone&.name },
              store: { name: object.shipment&.order&.store&.name }
            }
          }
        end
      end
    end
  end
end