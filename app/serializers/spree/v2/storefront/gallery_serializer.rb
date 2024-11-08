module Spree
  module V2
    module Storefront
      class GallerySerializer < BaseSerializer
        attributes :id, :image, :attachment_id

        attribute :image do |object|
          image_attributes = {filename: "", url: ""}
          attachment = object&.image&.attachment
          if attachment
            filename = attachment&.blob&.filename
            url = object.active_storge_url(attachment)
            image_attributes["filename"] = filename
            image_attributes["url"] = url
            image_attributes["id"] = object.image.id
          end
          image_attributes
        end
        
      end
    end
  end
end