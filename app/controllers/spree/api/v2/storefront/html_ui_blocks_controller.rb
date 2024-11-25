module Spree
  module Api
    module V2
      module Storefront
        class HtmlUiBlocksController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_store
          before_action :set_html_component
          before_action :set_html_ui_block, only: [:show, :update, :destroy]

          def index
            @html_ui_blocks = @html_component.html_ui_blocks
            render_serialized_payload { serialize_collection(@html_ui_blocks) }
          end

          def show
            render_serialized_payload { serialize_resource(@html_ui_block) }
          end

          def create
            html_ui_block = @html_component.html_ui_blocks.new(html_ui_block_params)
            if html_ui_block.save
              render_serialized_payload { serialize_resource(html_ui_block) }
            else
              render_error_payload(failure(html_ui_block).error)
            end
          end

          def update
            if @html_ui_block.update(html_ui_block_params)
              render_serialized_payload { serialize_resource(@html_ui_block) }
            else
              render_error_payload(failure(@html_ui_block).error)
            end
          end

          def destroy
            if @html_ui_block.destroy
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@html_ui_block).error)
            end
          end

          private

          def set_store
            @store = current_client.stores.find_by('spree_stores.id = ?', params[:my_store_id])
            @layout = @store.html_page.html_layout
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @layout
          end

          def set_html_component
            @html_component =  @layout.html_components.find_by('spree_html_components.id = ?', params[:html_component_id])
          end
          
          def set_html_ui_block
            @html_ui_block = @html_component.html_ui_blocks.find_by('spree_html_ui_blocks.id = ?', params[:id])
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @html_ui_block
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::HtmlUiBlockSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::HtmlUiBlockSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def html_ui_block_params
            params.require(:html_ui_block).permit(:title, :cta_label, :cta_link, :heading, :caption, :banner_item_description, :text_allignment, :font_color, :position, :type_of_html_ui_block, :link, :background_color, :attachment_id, :gallery_image_id, :alt,
                                                  :html_links_attributes  => [:id, :link, :name, :_destroy])
          end

        end
      end
    end
  end
end