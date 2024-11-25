module Spree
  module Api
    module V2
      module Storefront
        class HtmlComponentsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:navbar_data, :footer_data, :newletter_data]
          before_action :set_store, except: [:navbar_data, :footer_data, :newletter_data]
          before_action :set_html_component, only: [:show, :update, :destroy]
          before_action :set_html_publish_layout, only: [:navbar_data, :footer_data, :newletter_data]

          def index
            @html_components = @layout.html_components.includes(:html_ui_blocks)
            render_serialized_payload { serialize_collection(@html_components) }
          end

          def show
            render_serialized_payload { serialize_resource(@html_component) }
          end

          def create
            html_component = @layout.html_components.new(html_component_params)
            @layout.update_column(:publish, false)
            if html_component.save
              html_component.add_multi_banner
              render_serialized_payload { serialize_resource(html_component) }
            else
              render_error_payload(failure(html_component).error)
            end
          end

          def update
            if @html_component.update(html_component_params)
              @layout.update_column(:publish, false)
              render_serialized_payload { serialize_resource(@html_component) }
            else
              render_error_payload(failure(@html_component).error)
            end
          end

          def destroy
            if @html_component.destroy
              @layout.update_column(:publish, false)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@html_component).error)
            end
          end

          def destroy_logo
            if @layout.html_components.where(type_of_component:'logo').first.html_ui_blocks.first != nil
              @logo_component = @layout.html_components.where(type_of_component:'logo').first.html_ui_blocks.first
              if @logo_component.image.attachment
                @logo_component.image.destroy
              end
            end
          end

          def navbar_data
            navbar = @components&.where(type_of_component:'nav_bar')&.first
            render_serialized_payload { serialize_resource(navbar) }
          end

          def footer_data
            footer = @components&.where(type_of_component:'footer')&.first
            render_serialized_payload { serialize_resource(footer) }
          end

          def newletter_data
            newletter = @components&.where(type_of_component:'newsletter_cta')&.first&.html_ui_blocks&.first
            render_serialized_payload { Spree::V2::Storefront::HtmlUiBlockSerializer.new(newletter).serializable_hash }
          end

          def update_all_components
            @layout.update(html_layout_component_params)
            @layout.update_column(:publish, false)
            render_serialized_payload { serialize_resource(@layout.html_components) }
          end

          private

          def set_html_publish_layout
            @components = spree_current_store.html_page&.publish_html_layouts&.where(publish: true, active: true)&.first&.html_components
          end

          def set_store
            @store = current_client.stores.find_by('spree_stores.id = ?', params[:my_store_id])
            @layout = @store.html_page.html_layout
          end

          def set_html_component
            @html_component = @layout.html_components.find_by('spree_html_components.id = ?', params[:id])
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::HtmlComponentSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::HtmlComponentSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def html_component_params
            params.require(:html_component).permit(:name, :type_of_component, :no_of_images, :position, :heading,
                                                   html_ui_blocks_attributes: [:id, :title, :heading, :banner_item_description, :caption, :text_allignment, :font_color, :gallery_image_id, :position, :sort_order,:_destroy, :type_of_html_ui_block, :background_color, :link, :logo_url,
                                                                               :cta_label, :cta_link, :is_external_link, :alt, :attachment_id,
                                                                               html_links_attributes: [:id, :link, :is_external_link, :link_type, :name, :sort_order, :_destroy],
                                                                               html_ui_block_sections_attributes: [:id, :name, :type_of_section, :alt, :link, :is_external_link, :position, :gallery_image_id, :attachment_id, :_destroy,
                                                                                                                   :html_links_attributes  => [:id, :link, :is_external_link, :name, :sort_order, :_destroy]]])
          end

          def html_layout_component_params
            params.require(:html_layout).permit(html_components_attributes: [:id, :name, :type_of_component, :position, :heading])
          end

        end
      end
    end
  end
end
