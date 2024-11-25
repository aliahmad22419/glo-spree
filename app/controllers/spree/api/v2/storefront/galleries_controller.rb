module Spree
  module Api
    module V2
      module Storefront
        class GalleriesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :check_permissions
          before_action :set_gallery, only: [:show,:update,:destroy]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])

            @galleries = current_client.galleries
            if params[:q].present? && params[:q][:upload_type].eql?(:supported_images.to_s)
              @galleries = @galleries.supported_images
            end

            @galleries = @galleries.ransack(params[:q]).result(distinct: true).order("created_at DESC")
            @galleries = collection_paginator.new(@galleries, params).call
            render_serialized_payload { serialize_collection(@galleries) }
          end

          # def product_gallery
          #   @galleries = current_client.galleries.result(distinct: true).order("created_at DESC")
          #   @galleries = collection_paginator.new(@galleries, params).call
          #   render_serialized_payload { serialize_collection(@galleries) }
          # end

          def show
            render_serialized_payload { serialize_resource(@gallery) }
          end

          def new
            @gallery = Gallery.new
          end

          def edit
          end

          def create
            begin
              ActiveRecord::Base.transaction do
                params[:gallery].permit!
                params[:gallery][:attachment_ids].each { |attachment_id| 
                  @gallery = current_client.galleries.new(attachment_id: attachment_id)
                  raise ActiveRecord::Rollback unless @gallery.save
                }
              end
              render json: { success: true }, status: :ok
            rescue StandardError => e
              render_error_payload(failure(@gallery).error)
            end
          end

          def update
            params[:gallery].permit!
            if @gallery.update(attachment_id: params[:gallery][:attachment_ids].first)
              render_serialized_payload { serialize_resource(@gallery) }
            else
              render_error_payload(failure(@gallery).error)
            end
          end


          def destroy
            if @gallery.destroy
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@gallery).error)
            end
          end

          def destroy_multiple
            galleries = current_client.galleries.where(id: JSON.parse(params[:ids]))
            if galleries.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(galleries).error)
            end
          end

          private

            def set_gallery
              @gallery = current_client.galleries.find_by('spree_galleries.id = ?', params[:id])
              return render json: { error: "Gallery not found" }, status: 403 unless @gallery
            end

            def gallery_params
              params.require(:gallery).permit(:id, :attachment_id)
            end

            def serialize_collection(collection)
              Spree::V2::Storefront::GallerySerializer.new(
                  collection,
                  collection_options(collection)
              ).serializable_hash
            end

            def serialize_resource(resource)
              Spree::V2::Storefront::GallerySerializer.new(
                  resource,
                  include: resource_includes,
                  sparse_fields: sparse_fields
              ).serializable_hash
            end
        end
      end
    end
  end
end
