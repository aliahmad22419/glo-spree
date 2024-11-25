module Spree
  module Api
    module V2
      module Storefront
        class BulkOrdersController < ::Spree::Api::V2::BaseController
          ORDER_ASSOCIATED = [:line_items, :shipments, :payments, :ts_giftcards, :givex_cards, :store]

          before_action :require_spree_current_user, :require_spree_current_client, :authorize_client_or_sub_client
          before_action :set_bulk_order, only: [:show, :destroy]
          before_action :set_order, only:[:attach_shipping_address]
          before_action :reset_bulk_order, only: [:create]
          after_action  :save_csv, only: [:create]
          before_action :authorized_client_sub_client

          def index
            params[:q] = valid_json?(params[:q]) ? JSON.parse(params[:q]) : {}

            bulk_orders = Spree::BulkOrder.accessible_by(current_ability, :index).includes(order: ORDER_ASSOCIATED)
                                          .ransack(params[:q]).result.order(created_at: :desc)

            render_serialized_payload { serialize_collection( collection_paginator.new( bulk_orders, params ).call ) }
          end

          def show
            render_serialized_payload { serialize_resource(@spree_bulk_order) }
          end

          def create
            begin
              order = BulkCart.new.create_bulk_order(bulk_order_service_params)
              @bulk_order = spree_current_user.bulk_orders.create!({ client_id: current_client.id, state: 'cart' })
              order.update(bulk_order_id: @bulk_order.id)
              order.next!
              render_serialized_payload { serialize_resource(@bulk_order) }
            rescue Exception => exception
              render_error_payload(exception.message,422)
            end
          end

          def destroy
            if @spree_bulk_order.destroy
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure( @spree_bulk_order ).error)
            end
          end

          def attach_shipping_address
            begin
              BulkCart.new.attach_address(params, @order)
            rescue Exception => e
              render_error_payload(e.message,422)
            end
          end

          private
          def reset_bulk_order
            spree_current_user.bulk_orders.find_by(id: params[:id])&.destroy
          end

          def bulk_order_service_params
            params.slice(:currency, :store_id, :email, :csv_file).merge(user: spree_current_user)
          end

          def save_csv
            @bulk_order&.update(csv_file: params[:csv_file]) if @bulk_order
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::BulkOrderSerializer.new(
              collection,
              collection_options(collection)
            ).serializable_hash
          end

          def collection_options(collection)
            {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: resource_includes,
              fields: sparse_fields,
              params: { serialize_order: false }
            }
          end
          
          def serialize_resource(resource)
            Spree::V2::Storefront::BulkOrderSerializer.new(resource).serializable_hash
          end

          def set_bulk_order
            @spree_bulk_order = Spree::BulkOrder.accessible_by(current_ability, :show).find_by('spree_bulk_orders.id = ?', params[:id])
            render json: { error: I18n.t('spree.bulk_order.not_authorize')}.to_json, status: 403 unless @spree_bulk_order.present?
          end

          def set_order
            @order = Spree::Order.find_by('spree_orders.id = ?', params[:order_id])
          end

        end
      end
    end
  end
end
