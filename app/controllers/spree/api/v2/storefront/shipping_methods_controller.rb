module Spree
  module Api
    module V2
      module Storefront
        class ShippingMethodsController < ::Spree::Api::V2::BaseController
          
          before_action :require_spree_current_user
          before_action :set_vendor
          before_action :set_shipping_method, only: [:show, :update, :destroy]
          before_action :authorized_client_sub_client_vendor, only: [:create, :update, :destroy]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            shipping_methods = Spree::ShippingMethod.accessible_by(current_ability, :index).ransack(params[:q]).result(distinct: true).order(created_at: :desc)
            shipping_methods = shipping_methods.where(delivery_mode: nil) if params[:q] && params[:q][:delivery_mode_cont] == ""
            shipping_methods = collection_paginator.new(shipping_methods, params).call
            render_serialized_payload { serialize_collection(shipping_methods) }
          end

          def show
            render_serialized_payload { serialize_resource(@shipping_method) }
          end

          def update
            params[:calculator_attributes].permit!
            shipping_method_params_hash = {shipping_category_ids: params[:shipping_categories], zone_ids: params[:zones], calculator_type: params[:calculator_type]}
            if @shipping_method.update(shipping_method_params.merge(shipping_method_params_hash))
              @shipping_method.calculator.update_attribute(:preferences, params[:calculator_attributes].to_h.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}) if params[:calculator_attributes].present?
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@shipping_method).error)
            end
          end

          def create
            shipping_method_params_hash = {shipping_category_ids: params[:shipping_categories], zone_ids: params[:zones], calculator_type: params[:calculator_type], client_id: current_client&.id}
            
            shipping_method = if @spree_current_user.present? && (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              current_client.shipping_methods.new(shipping_method_params.merge(shipping_method_params_hash))
            else
              @vendor.shipping_methods.new(shipping_method_params.merge(shipping_method_params_hash))
            end

            if shipping_method.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(shipping_method).error)
            end
          end

          def destroy
            if @shipping_method.destroy
              render_serialized_payload { serialize_resource(@shipping_method) }
            else
              render_error_payload(failure(@shipping_method).error)
            end
          end

          def form_data
            data = {}
            shipping_attributes =  []
            shipping_categories  = current_client.present? ? current_client.shipping_categories.order(:name) : Spree::ShippingCategory.order(:name).all
            shipping_categories.each do |sc|
              shipping_attributes.push({id: sc.id, name: sc.name, is_weighted: sc.is_weighted})
            end
            data["shipping_categories"] = shipping_attributes
            zone_attributes =  []
            zones = current_client.present? ? current_client.zones.order(:name) : Spree::Zone.order(:name).all
            zones.each do |zone|
              zone_attributes.push({id: zone.id, name: zone.name})
            end
            data["zones"] = zone_attributes
            tax_categories_attributes =  []
            tax_categories = current_client.present? ? current_client.tax_categories.order(:name) : Spree::TaxCategory.order(:name).all
            tax_categories.each do |tc|
              tax_categories_attributes.push({id: tc.id, name: tc.name})
            end
            data["tax_categories"] = tax_categories_attributes
            calculator_attributes =  []
            shipping_method_cal = current_client.present? ? current_client.shipping_methods.calculators.sort_by(&:name) : Spree::ShippingMethod.calculators.sort_by(&:name)
            shipping_method_cal.each do |cal|
              calculator_attributes.push({name: cal.description, type: cal.name})
            end
            data["calculators"] = calculator_attributes
            data["stores"] = current_client.stores.map{|store| {name: store.name, id: store.id}}
            render json: data.to_json
          end

          private

          def set_vendor
            @vendor = @spree_current_user&.vendors&.first
          end

          def valid_json?(json)
            begin
              JSON.parse(json)
              return true
            rescue Exception => e
              return false
            end
          end
          
          def serialize_collection(collection)
            Spree::V2::Storefront::ShippingMethodSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::ShippingMethodSerializer.new(resource).serializable_hash
          end

          def set_shipping_method
            @shipping_method = if @vendor.present?
              current_client.shipping_methods.where(vendor_id: @vendor.id).find_by('spree_shipping_methods.id = ?', params[:id])
            elsif current_client.present?
              current_client.shipping_methods.find_by('spree_shipping_methods.id = ?', params[:id])
            end

            return render json: { error: "Shipping Method not found" }, status: 403 unless @shipping_method
          end

          def shipping_method_params
            params.require(:shipping_method).permit(:scheduled_fulfilled, :schedule_days_threshold, :name, :display_on, :tracking_url, :admin_name, :tax_category_id, :code,
                                                    :visible_to_vendors, :delivery_mode, :delivery_threshold, :cutt_off_time, :lalamove_enabled, :lalamove_service_type, :auto_schedule_lalamove, :hide_shipping_method,:is_weighted ,store_ids: [],
                                                    time_slots_attributes: [:id, :start_time, :end_time, :_destroy], weights_attributes: [:id, :maximum, :minimum, :price, :_destroy])
          end

        end
      end
    end
  end
end
