module Spree
  module V2
    module Storefront
      class GivexCardSerializer < BaseSerializer
        set_type :order
        attributes :id,:givex_number, :customer_email, :balance, :invoice_id, :currency, :send_gift_card_via, :receipient_phone_number, :active_card, :created_at, :expiry_date,:iso_code, :givex_response

        attribute :hidden_givex_number do |givex|
          givex.is_gift_card_number_display(givex.givex_number,givex.client)
        end

        attribute :store_data do |object|
          {name: object&.store&.name}
        end

        attribute :currency_symbol do |object|
          Spree::Money.new(object&.currency)&.currency&.symbol
        end

        attribute :card_response do |object|
          card_response = JSON.parse(object.givex_response) rescue {}
          card_response_comments = (card_response["success"] && card_response["value"]["result"].present? && card_response["value"]["result"][7] rescue nil)
          card_response_comments = card_response["result"] && card_response["result"][7] if card_response_comments.blank?
          {issued_on: object&.created_at.to_date, expiry_date: object&.expiry_date, comments: card_response_comments.present? ? card_response_comments : (object.comments.present? ? object.comments : 'No Comments')}
        end

        attribute :creator_role do |object|
            object&.user&.spree_roles&.first&.name&.gsub('client','admin') if !object.order_id.present?
        end

        attribute :creator_email do |object|
        object&.user&.email if !object.order_id.present?
      end
      end
    end
  end
end
