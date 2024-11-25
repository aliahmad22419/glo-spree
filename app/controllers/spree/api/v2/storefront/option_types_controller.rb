module Spree
	module Api
		module V2
			module Storefront
				class OptionTypesController < ::Spree::Api::V2::BaseController
					
					before_action :require_spree_current_user
					before_action :set_option_type, only: [:show, :update, :destroy, :reply]
					before_action :check_permissions
					
					def index
						params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
						option_types = Spree::OptionType.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
						option_types = collection_paginator.new(option_types, params).call
						render_serialized_payload { serialize_collection(option_types) }
					end
					
					def show
						render_serialized_payload { serialize_resource(@option_type) }
					end
					
					def update
						if @option_type.update(option_type_params)
							render_serialized_payload { serialize_resource(@option_type) }
						else
							render_error_payload(failure(@option_type).error)
						end
					end
					
					def create
						option_type = current_client.option_types.new(option_type_params)
						if option_type.save
							render_serialized_payload { serialize_resource(option_type) }
						else
							render_error_payload(failure(option_type).error)
						end
					end
					
					def destroy
						if @option_type.destroy
							render_serialized_payload { serialize_resource(@option_type) }
						else
							render_error_payload(failure(@option_type).error)
						end
					end
					
					private
						
						def serialize_collection(collection)
							Spree::V2::Storefront::OptionTypeSerializer.new(
									collection,
									collection_options(collection)
							).serializable_hash
						end
						
						def serialize_resource(resource)
							Spree::V2::Storefront::OptionTypeSerializer.new(
									resource,
									include: resource_includes,
									sparse_fields: sparse_fields
							).serializable_hash
						end
					
					def set_option_type
						@option_type = current_client.option_types.find_by('spree_option_types.id = ?', params[:id])
						return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @option_type
					end
					
					def option_type_params
						params.require(:option_type).permit(:name, :presentation, :position, option_values_attributes: [:id, :position, :name, :presentation, :_destroy])
					end
				
				end
			end
		end
	end
end
