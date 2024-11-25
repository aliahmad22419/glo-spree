module Spree
  module Api
    module V2
      module Storefront
        module OrderConcern
          private

          def cart_synced_cross_browser?
            return [spree_current_order.cart_token, "null", nil].include? requests_cart_token
          end

          def cart_synced_json
            order = get_cart_order
            if cart_synced_cross_browser? 
              { message: 'synched', synched_cart: true, status_code: 200 }
            else
              {
                message: (order.complete? ? Spree.t(:order_completed_already) : Spree.t(:outdated_cross_browser_cart)),
                synched_cart: false,
                status_code: 409
              }
            end
          end
          
          def validate_cart_changed
            order = get_cart_order
            order.update(cart_token: nil) if order.cart_token.present?
          end

          def ensure_synced_cross_browser_cart
            cart_message = cart_synced_json
            render_error_payload(cart_message[:message], cart_message[:status_code]) and return unless cart_message[:synched_cart]
          end

          def requests_cart_token
            request.headers['X-Spree-Cart-Token'] || params[:cart_token]
          end

          def get_cart_order
            Spree::Order.find_by(token: order_token) || spree_current_order
          end

          def render_order(result)
            if result.success?
              render_serialized_payload { serialized_current_order }
            else
              render_error_payload(result.error)
            end
          end
          def ensure_order
            raise ActiveRecord::RecordNotFound if spree_current_order.nil?
          end
          def order_token
            request.headers['X-Spree-Order-Token'] || params[:order_token]
          end
          def spree_current_order
            @spree_current_order ||= find_spree_current_order 
          end
          def find_spree_current_order
            Spree::Api::Dependencies.storefront_current_order_finder.constantize.new.execute(
              store: spree_current_store,
              user: spree_current_user,
              token: order_token,
              currency: current_currency
            )
          end
          def serialize_order(order)
            resource_serializer.new(order.reload, include: resource_includes, fields: sparse_fields).serializable_hash
          end
          def serialized_current_order
            serialize_order(spree_current_order)
          end
        end
      end
    end
  end
end
