module Spree
  module Api
    module V2
      module Storefront
        class ReturnAuthorizationsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, only: [:return_authorization_params, :get_reimbursements_data]
          before_action :refund_amount, only: [:create]

          def create
            @return_authorization = order.return_authorizations.build(return_authorization_params)

            if @return_authorization.save
              arr = @return_authorization.return_items
              raw_parameters = {
                "select-all": "1",
                "customer_return": {
                  "return_items_attributes": {
                  },
                  "stock_location_id": return_authorization_params[:stock_location_id],
                  "store_id": order.store_id
                }
              }
              arr.each_with_index { |(key,value), index| raw_parameters[:customer_return][:return_items_attributes].merge!("#{index}": {}) }
              arr.each_with_index { |(key,value), index| raw_parameters[:customer_return][:return_items_attributes][:"#{index}"].merge!("return_authorization_id": "#{key.return_authorization_id}", "inventory_unit_id": "#{key.inventory_unit_id}", "pre_tax_amount": "#{key.pre_tax_amount}", "returned": "1", "resellable"=>"1", "id": "#{key.id}", "exchange_variant_id":"#{key.exchange_variant_id}" ) }

              params = ActionController::Parameters.new(raw_parameters)
              build_customer_returns(params)
            else
              render :json => {:error => @return_authorization.errors.full_messages}.to_json
            end
          end

          def get_reimbursements_data
            roles = spree_current_user.spree_roles.map(&:name)
            if (roles.include?"client")
              vendor = spree_current_user.client.master_vendor
            elsif (roles.include?"vendor")
              vendor = spree_current_user.vendors.first
            end
            params[:q] = {}
            params[:q][:shipments_vendor_id_eq] = vendor.id
            orders = Spree::Order.complete.ransack(params[:q]).result(distinct: true).order("completed_at DESC")
            serialize_collection_without_pagination(orders)
            @user_order_ids = orders.pluck(:id)
            @reimbursements = Spree::Reimbursement.where(order_id: @user_order_ids).order("created_at DESC")
            render_serialized_payload { serialize_reimbursement_collection(@reimbursements) }
          end

          private

          def create_order(exchanged_variant_id, return_quantity, line_item_id)
            new_order = Spree::Order.new(email: order.email, currency: order.currency, user_id: order.user_id, store_id: order.store_id)
            new_order["ship_address_id"] = order.ship_address_id
            new_order["bill_address_id"] = order.bill_address_id
            new_order.save!
            variant = Spree::Variant.find_by('spree_variants.id = ?', exchanged_variant_id)
            Spree::Cart::AddItem.call(order: new_order, variant: variant, quantity: return_quantity)
            line_item = Spree::LineItem.find_by('spree_line_items.id = ?', line_item_id)
            line_item_exchage_rates = line_item.line_item_exchange_rate.dup
            line_item_exchage_rates.line_item_id = new_order.line_items.first.id
            line_item_exchage_rates.save
            Spree::Checkout::GetShippingRates.call(order: new_order)
            shipment = new_order.shipments.includes(shipping_rates: :shipment).last
            shipments_with_rates = shipment.shipping_rates
            shipping_method_id = order.inventory_units.find_by(line_item_id: line_item_id).shipment.shipping_method.id
            shipment_rate = shipments_with_rates.select{|shipping_rate| shipping_rate.shipping_method.id ==  shipping_method_id }&.last
            shipment.selected_shipping_rate = shipment_rate if shipment_rate.present?
            new_order.update({:state => "complete", :payment_state => "paid", :completed_at => Time.now})
            stock_item = line_item.product.stock_items.find_by(variant_id: exchanged_variant_id)
            Spree::StockMovement.create!(
              stock_item_id: stock_item.id,
              quantity: -return_quantity,
              originator_type: "Spree::Shipment",
              originator_id: shipping_method_id
            )
          end

          def serialize_collection_without_pagination(collection)
            Spree::V2::Storefront::VendorOrderSerializer.new(
              collection,
              {
                fields: sparse_fields
              }
            ).serializable_hash
          end

          def serialize_reimbursement_collection(collection)
            Spree::V2::Storefront::ReimbursementSerializer.new(
              collection,
              {
                fields: sparse_fields
              }
            ).serializable_hash
          end

          def order
            @order ||= Spree::Order.find_by('spree_orders.id = ?', params[:order_id])
          end

          def return_authorization_params
            roles = spree_current_user.spree_roles.map(&:name)
            if (roles.include?"client")
              stock_location_id = spree_current_user.client.master_vendor.stock_locations.first.id
            elsif (roles.include?"vendor")
              stock_location_id = spree_current_user.vendors.first.stock_locations.first.id
            end

            params[:return_authorization] = params[:return_authorization].merge(:stock_location_id => "#{stock_location_id}")
            params[:return_authorization] = params[:return_authorization].merge(:return_authorization_reason_id => "4")

            params.require(:return_authorization).permit(
              :exchanged_difference,
              :stock_location_id,
              :return_authorization_reason_id,
              :memo,
              return_items_attributes: [:inventory_unit_id, :return_quantity, :pre_tax_amount, :exchange_variant_id]
            )
          end

          def permitted_resource_params
            @permitted_resource_params ||= params.require('customer_return').permit(
              :exchanged_difference,
              :stock_location_id,
              :store_id,
              return_items_attributes: [:inventory_unit_id, :return_authorization_id, :pre_tax_amount, :returned, :resellable, :id]
            )
          end

          def refund_amount
            @refund_price = params[:refund_price]
          end

          def build_customer_returns(params)
            @permitted_resource_params ||= params.require('customer_return').permit(
              :stock_location_id,
              :store_id,
              return_items_attributes: [:inventory_unit_id, :return_authorization_id, :pre_tax_amount, :returned, :resellable, :id]
            )
            @customer_return = Spree::CustomerReturn.new
            return_items_params = @permitted_resource_params.delete(:return_items_attributes).values

            @customer_return.return_items = return_items_params.map do |item_params|
              next unless item_params.delete('returned') == '1'

              return_item = item_params[:id] ? Spree::ReturnItem.find_by(id: item_params[:id]) : Spree::ReturnItem.new
              return_item.attributes = item_params
              return_item
            end.compact

            @customer_return.attributes = permitted_resource_params
            if !@customer_return.save
              render :json => {:error => @customer_return.errors.full_messages}
            end
            return_items = params["customer_return"]["return_items_attributes"]

            create_reimbursement(@customer_return)
          end

          def create_reimbursement(customer_return)
            @reimbursement = Spree::Reimbursement.build_from_customer_return(customer_return)
            @reimbursement.total = @refund_price

            if @reimbursement.save
              return_items = params[:return_authorization][:return_items_attributes]
              return_items.each do |key, value|
                if value["exchange_variant_id"] != ""
                  create_order(value["exchange_variant_id"], value["return_quantity"], value["line_item_id"])
                end
              end

              Spree::RefundRequestMailer.refund_accepted_mail(@reimbursement).deliver_now
              render json: { success: "Items were refunded successfully." }.to_json
            else
              render json: { error: @reimbursement.errors.full_messages }.to_json
            end
          end
        end
      end
    end
  end
end
