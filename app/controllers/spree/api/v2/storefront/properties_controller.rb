module Spree
	module Api
		module V2
			module Storefront
				class PropertiesController < ::Spree::Api::V2::BaseController
					
					before_action :require_spree_current_user
					before_action :set_property, only: [:show, :update, :destroy, :reply]
					before_action :patch_stores, only:[:update], :if => Proc.new{ @spree_current_user.user_with_role("sub_client") == true }
					before_action :check_permissions
					
					def index
						params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
						properties = Spree::Property.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
						properties = collection_paginator.new(properties, params).call
						render_serialized_payload { serialize_collection(properties) }
					end
					
					def show
						render_serialized_payload { serialize_resource(@property) }
					end
					
					def update
						if @property.update(property_params)
							render_serialized_payload { serialize_resource(@property) }
						else
							render_error_payload(failure(@property).error)
						end
					end
					
					def create
						property = current_client.properties.new(property_params)
						if property.save
							render_serialized_payload { serialize_resource(property) }
						else
							render_error_payload(failure(property).error)
						end
					end
					
					def destroy
						if @property.destroy
							render_serialized_payload { serialize_resource(@property) }
						else
							render_error_payload(failure(@property).error)
						end
					end
					
					private

						def patch_stores
							params_stores = params[:property][:store_ids]
							object_stores = @property.store_ids.map{|id| id.to_s}
							if params_stores
								object_stores = (object_stores - @spree_current_user.allow_store_ids).uniq
								params[:property][:store_ids] = (object_stores + params_stores).uniq
							else
								params[:property][:store_ids] = (object_stores - @spree_current_user.allow_store_ids).uniq
							end
						end
						
						def serialize_collection(collection)
							Spree::V2::Storefront::PropertySerializer.new(
									collection,
									collection_options(collection)
							).serializable_hash
						end
						
						def serialize_resource(resource)
							Spree::V2::Storefront::PropertySerializer.new(
									resource,
									include: resource_includes,
									sparse_fields: sparse_fields
							).serializable_hash
						end
					
					def set_property
						@property = current_client.properties.find_by('spree_properties.id = ?', params[:id])
						return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @property
					end
					
					def property_params
						params.require(:property).permit(:name, :presentation, :filterable, :values, :store_ids => [])
					end
				
				end
			end
		end
	end
end
