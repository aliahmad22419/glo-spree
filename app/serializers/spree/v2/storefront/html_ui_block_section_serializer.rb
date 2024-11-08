module Spree
  module V2
    module Storefront
      class HtmlUiBlockSectionSerializer < BaseSerializer
        attributes :id, :name, :type_of_section, :alt, :link, :position, :attachment_id, :gallery_image_id, :is_external_link

        attribute :image do |object|
          image_attributes = {filename: "", url: ""}
          attachment = object&.image&.attachment
          if attachment
            filename = attachment&.blob&.filename
            url = object.active_storge_url(attachment)
            image_attributes["filename"] = filename
            image_attributes["url"] = url
          end
          image_attributes
        end

        attribute :html_links_attributes do |object|
          object&.html_links
        end

      end
    end
  end
end
