module Spree
  module Api
    module V2
      module Storefront
        class ZonesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_zone, only: [:show, :update, :destroy, :update_fulfilment_zone, :assign_order]
          before_action :check_duplicate_countries, only: [:create_fulfilment_zone, :update_fulfilment_zone]
          before_action :check_permissions
          def create
            zone = current_client.zones.new(zone_params)
            create_zone zone
          end

          def create_fulfilment_zone
            # render_unauthorized_access if spree_current_user.has_spree_role?(:fulfilment_user)
            zone = Spree::Zone.new(zone_params.merge({creator_id: spree_current_user.id}))
            create_zone zone
          end

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            zones = Spree::Zone.accessible_by(current_ability, :index).ransack(params[:q]).result&.order("created_at DESC")
            zones = collection_paginator.new(zones, params).call
            render_serialized_payload { serialize_collection(zones) }
          end

          def show
            render_serialized_payload { serialize_resource(@zone) }
          end

          def update
            if @zone.update(zone_params)
              render_serialized_payload { serialize_resource(@zone) }
            else
              render_error_payload(failure(@zone).error)
            end
          end

          def update_fulfilment_zone
            # render_unauthorized_access if spree_current_user.has_spree_role?(:fulfilment_user)
            update
          end

          def destroy
            if @zone.destroy
              render_serialized_payload { serialize_resource(@zone) }
            else
              render_error_payload(failure(@zone).error)
            end
          end

          def assign_order
            orders = Spree::Order.accessible_by(current_ability).where('spree_orders.id IN (?)', params[:order_ids])
            if @zone && orders.any?
              if orders.update_all(zone_id: params[:id])
                render json: {success: true, status: 200}
              else
                render json: {status: :unprocessable_entity}
              end
            end
          end

          private

          def create_zone zone
            if zone.save
              render_serialized_payload { serialize_resource(zone) }
            else
              render_error_payload(failure(zone).error)
            end
          end

          def check_duplicate_countries
            zone = @zone || Spree::Zone.new
            countries = zone.validate_unique_country_ids(params[:zone])
            return render json: {error: "#{countries.join(", ")} already assigned to another zone"}, status: :unprocessable_entity if countries.present?
          end

          def set_zone
            @zone = current_client ? current_client.zones.find_by('spree_zones.id = ?', params[:id]) : Spree::Zone.accessible_by(current_ability, :index).find_by('spree_zones.id = ?', params[:id])
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @zone
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::ZoneSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::ZoneSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def zone_params
            params.require(:zone).permit(:name, :description, :default_tax, :kind, :fulfilment_zone,:zone_code, :country_ids => [], :state_ids => [])
          end

        end
      end
    end
  end
end
