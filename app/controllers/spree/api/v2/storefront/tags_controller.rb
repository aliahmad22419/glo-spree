module Spree
	module Api
		module V2
			module Storefront
				class TagsController < ::Spree::Api::V2::BaseController
					
					before_action :require_spree_current_user
					before_action :set_tag, only: [:show, :update, :destroy]
					before_action :check_permissions
					
					def index
						params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
						tags = Spree::Tag.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
						render_serialized_payload { serialize_collection(tags) }
					end
					
					def show
						render_serialized_payload { serialize_resource(@tag) }
					end
					
					def update
						if @tag.update(tag_params)
							render_serialized_payload { success({success: true}).value }
						else
							render_error_payload(failure(@tag).error)
						end
					end
					
					def create
						tag = Spree::Tag.new(tag_params.merge(client_id: current_client.id))
						if tag.save
							render_serialized_payload { success({success: true}).value }
						else
							render_error_payload(failure(tag).error)
						end
					end
					
					def destroy
						if @tag.destroy
							render_serialized_payload { serialize_resource(@tag) }
						else
							render_error_payload(failure(@tag).error)
						end
					end

					private
						
						def serialize_collection(collection)
							Spree::V2::Storefront::TagSerializer.new(
									collection,
									collection_options(collection)
							).serializable_hash
						end
						
						def serialize_resource(resource)
							Spree::V2::Storefront::TagSerializer.new(
									resource,
									include: resource_includes,
									sparse_fields: sparse_fields
							).serializable_hash
						end
					
					def set_tag
						@tag = Spree::Tag.accessible_by(current_ability, :show).find_by('spree_tags.id = ?', params[:id])
					end
					
					def tag_params
						params.require(:tag).permit(:name)
					end
				
				end
			end
		end
	end
end
