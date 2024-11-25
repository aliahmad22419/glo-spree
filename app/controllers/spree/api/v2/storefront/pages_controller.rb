module Spree
  module Api
    module V2
      module Storefront
        class PagesController < ::Spree::Api::V2::BaseController
          
          before_action :require_spree_current_user, except: [:get_by_url]
          before_action :storefront_client_not_found, only: [:get_by_url]
          before_action :set_page, only: [:show, :update, :destroy]
          before_action :set_store_ids, only: [:create, :update]
          before_action :patch_stores, only:[:update], :if => Proc.new{ @spree_current_user.user_with_role("sub_client") == true }
          before_action :check_permissions


          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            pages = Spree::Page.accessible_by(current_ability, :index).ransack(params[:q]).result.order("sort_order asc")
            pages = collection_paginator.new(pages, params).call
            render_serialized_payload { serialize_collection(pages) }
          end

          def show
            render_serialized_payload { serialize_resource(@page) }
          end

          def get_by_url
            @page = spree_current_store.pages.static.find_by(url: params[:id])
            render_serialized_payload { serialize_resource(@page) }
          end

          def update
            if @page.update(page_params.merge(store_ids: @store_ids))
              render_serialized_payload { serialize_resource(@page) }
            else
              render_error_payload(failure(@page).error)
            end
          end

          def create
            append_client_id = {client_id: current_client&.id, store_ids: @store_ids}
            page = Spree::Page.new(page_params.merge(append_client_id))
            if page.save
              render_serialized_payload { serialize_resource(page) }
            else
              render_error_payload(failure(page).error)
            end
          end
          def destroy
            if @page.destroy
              render_serialized_payload { serialize_resource(@page) }
            else
              render_error_payload(failure(@page).error)
            end
          end

          def destroy_multiple
            pages = Spree::Page.accessible_by(current_ability, :index).where('spree_pages.id IN (?)', JSON.parse(params[:ids]))
            raise ActionController::BadRequest.new(), "Invalid Request: You have attempted an invalid request to server." if (JSON.parse(params[:ids]).present? && pages.none?)
            if pages.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(pages).error)
            end
          end

          private

          def patch_stores
            params_stores = params[:page][:store_ids]
            object_stores = @page.store_ids.map{|id| id.to_s}
            if params_stores
              object_stores = (object_stores - @spree_current_user.allow_store_ids).uniq
              params[:page][:store_ids] = (object_stores + params_stores).uniq
            else
              params[:page][:store_ids] = (object_stores - @spree_current_user.allow_store_ids).uniq
            end
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::PageSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::PageSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_store_ids
            @store_ids = Spree::Store.accessible_by(current_ability, :index).pluck(:id) &  params[:store_ids].collect(&:to_i) if params[:store_ids].present?
          end

          def set_page
            @page = Spree::Page.accessible_by(current_ability, :show).find_by('spree_pages.id = ?', params[:id])
            return render json: { error: "Page not found" }, status: 403 unless @page
          end

          def page_params
            params.require(:page).permit(:title, :sort_order, :status, :heading, :content,:meta_desc, :url, :static_page, :store_ids => [])
          end

        end
      end
    end
  end
end
