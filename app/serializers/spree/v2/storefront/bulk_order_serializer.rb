module Spree
  module V2
    module Storefront
      class BulkOrderSerializer < BaseSerializer
        set_type :bulk_order

        attribute :order_id, :order_number, :order_state, :order_email

        attribute :store_name do |object|
          object.order&.store&.name
        end

        attribute :bulk_payment_state do |object|
          states = object.order.payments.pluck(:state).uniq.compact

          if object.order.payment_state.eql?('paid')
            'Completed'
          elsif states.present? && states.all?{ |state| state.downcase == 'failed' }
            'Failed'
          elsif object.order.payment_state.eql?('credit_owed')
            "Credit Owed"
          else 'Pending' end
        end

        attribute :order do |object, params|
          unless params[:serialize_order] == false
            Spree::V2::Storefront::OrderSerializer.new( object.order).serializable_hash
          end
        end

        attribute :order_tag_names do |object|
          object&.order&.order_tags&.pluck('label_name')&.join(',')
        end
      end
    end
  end
end