module Spree
	module Api
		module V2
			module Storefront
				class OrderTagsController < ::Spree::Api::V2::BaseController
					
					before_action :require_spree_current_user
					before_action :set_order_tag, only: [:show, :update, :destroy]
					before_action :check_permissions

					
					def index
						params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
						option_types = current_client.order_tags.ransack(params[:q]).result.order("id DESC")
						render_serialized_payload { serialize_collection(option_types) }
					end
					
					def show
						render_serialized_payload { serialize_resource(@order_tag) }
					end
					
					def update
						if @order_tag.update(order_tag_params)
							render_serialized_payload { success({success: true}).value }
						else
							render_error_payload(failure(@order_tag).error)
						end
					end
					
					def create
						order_tag = current_client.order_tags.new(order_tag_params)
						if order_tag.save
							render_serialized_payload { success({success: true}).value }
						else
							render_error_payload(failure(order_tag).error)
						end
					end
					
					def destroy
						if @order_tag.orders.present?
							render_error_payload(failure(@order_tag, "Order Tag can't be delete because, tag is associated to order(s)").error)
						else
							if @order_tag.destroy
								render_serialized_payload { serialize_resource(@order_tag) }
							else
								render_error_payload(failure(@order_tag).error)
							end
						end
					end

					def send_email
						order_tag = Spree::OrderTagsOrder.find_by(order_tag_id: params[:id], order_id: params[:order_id])
						if params[:removed] == true
							order_tag.send_email_tag_removed_to_intimation
						else
							order_tag.send_email_tag_added_to_intimation
						end
						render_serialized_payload { success({success: true}).value }
					end
					
					private
						
						def serialize_collection(collection)
							Spree::V2::Storefront::OrderTagSerializer.new(
									collection,
									collection_options(collection)
							).serializable_hash
						end
						
						def serialize_resource(resource)
							Spree::V2::Storefront::OrderTagSerializer.new(
									resource,
									include: resource_includes,
									sparse_fields: sparse_fields
							).serializable_hash
						end
					
					def set_order_tag
						@order_tag = current_client.order_tags.find_by('spree_order_tags.id = ?', params[:id])
						return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @order_tag
					end
					
					def order_tag_params
						params.require(:order_tag).permit(:label_name, :intimation_email)
					end
				
				end
			end
		end
	end
end
