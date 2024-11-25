module Spree
  module Api
    module V2
      module Storefront
        class TaxRatesController < ::Spree::Api::V2::BaseController
          
          before_action :require_spree_current_user
          before_action :set_tax_rate, only: [:show, :update, :destroy]
					before_action :check_permissions


          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            tax_rates = Spree::TaxRate.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
            tax_rates = collection_paginator.new(tax_rates, params).call
            render_serialized_payload { serialize_collection(tax_rates) }
          end

          def show
            render_serialized_payload { serialize_resource(@tax_rate) }
          end

          def update
            tax_rate_params_hash = {zone_id: params[:zones], calculator_type: params[:calculator_type]}
            if @tax_rate.update(tax_rate_params.merge(tax_rate_params_hash))
              @tax_rate.calculator.update_attribute(:preferences, params[:calculator_attributes].to_h.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}) if params[:calculator_attributes].present?
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@tax_rate).error)
            end
          end

          def create
            tax_rate_params_hash = {zone_id: params[:zones], calculator_type: params[:calculator_type], client_id: current_client&.id}
            tax_rate = current_client.tax_rates.new(tax_rate_params.merge(tax_rate_params_hash))
            if tax_rate.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(tax_rate).error)
            end
          end

          def destroy
            if @tax_rate.destroy
              render_serialized_payload { serialize_resource(@tax_rate) }
            else
              render_error_payload(failure(@tax_rate).error)
            end
          end

          def destroy_multiple
            tax_rates = current_client.tax_rates.where(id: JSON.parse(params[:ids]))
            return render json: { error: "Tax Rates not found" }, status: 404 unless tax_rates.any?
            if tax_rates.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(tax_rates).error)
            end
          end

          def form_data
            data = {}
            zone_attributes =  []
            zones = current_client.zones.order(:name)
            zones.each do |zone|
              zone_attributes.push({id: zone.id, name: zone.name})
            end
            data["zones"] = zone_attributes
            tax_categories_attributes =  []
            tax_categories = current_client.tax_categories.order(:name)
            tax_categories.each do |tc|
              tax_categories_attributes.push({id: tc.id, name: tc.name})
            end
            data["tax_categories"] = tax_categories_attributes
            calculator_attributes =  []
            tax_rate_cal = Spree::TaxRate.calculators
            tax_rate_cal.each do |cal|
              calculator_attributes.push({name: cal.description, type: cal.name})
            end
            data["calculators"] = calculator_attributes
            render json: data.to_json
          end

          private

          def valid_json?(json)
            begin
              JSON.parse(json)
              return true
            rescue Exception => e
              return false
            end
          end
          
          def serialize_collection(collection)
            Spree::V2::Storefront::TaxRateSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::TaxRateSerializer.new(resource).serializable_hash
          end

          def set_tax_rate
            @tax_rate = Spree::TaxRate.accessible_by(current_ability).find_by('spree_tax_rates.id = ?', params[:id])
            return render json: { error: "Tax Rate not found" }, status: 403 unless @tax_rate
          end

          def tax_rate_params
            params.require(:tax_rate).permit(:name, :amount, :show_rate_in_label, :included_in_price, :tax_category_id)
          end

        end
      end
    end
  end
end
