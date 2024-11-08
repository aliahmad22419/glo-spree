module Spree
  module V2
    module Storefront
      class HtmlUiBlockSerializer < BaseSerializer
        attributes :id, :title, :cta_label, :cta_link, :heading, :banner_item_description, :caption, :text_allignment, :font_color, :position,
                   :background_color, :alt, :type_of_html_ui_block, :link, :html_links, :attachment_id, :gallery_image_id, :is_external_link, :logo_url

        attribute :image do |object|
          image_attributes = {filename: "", url: ""}
          attachment = object&.image&.attachment
          if attachment
            filename = attachment&.blob&.filename
            url = object.active_storge_url(attachment)
            image_attributes["filename"] = filename
            image_attributes["url"] = url
            image_attributes["id"] = object&.image&.attachment&.blob.id
          end
          image_attributes
        end

        attribute :html_ui_block_sections do |object|
          Spree::V2::Storefront::HtmlUiBlockSectionSerializer.new(object.html_ui_block_sections).serializable_hash
        end

      end
    end
  end
end
