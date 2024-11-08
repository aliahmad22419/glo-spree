# Spree::V2::Storefront::TaxonSerializer.class_eval do

#   attributes :slug, :description, :banner_position, :banner_text

#   attributes :banner_image do |object|
#     image_attributes = {filename: "", url: ""}
#     attachment = object&.image&.attachment
#     if attachment
#       filename = attachment&.blob&.filename
#       url = object.active_storge_url(attachment)
#       image_attributes["filename"] = filename
#       image_attributes["url"] = url
#       image_attributes["id"] = object.image.id
#     end
#     image_attributes
#   end

#   attributes :breadcrums do |active|
#     active.ancestors.collect{ |anc| {id: anc.id, name: anc.name, slug: anc.slug, permalink: anc.permalink} }
#   end
# end

module Spree::V2::Storefront::TaxonSerializerDecorator

  def self.prepended(base)
    base.attributes :slug, :description, :banner_position, :banner_text

    base.attributes :banner_image do |object|
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

    base.attributes :breadcrums do |active|
      active.ancestors.collect{ |anc| {id: anc.id, name: anc.name, slug: anc.slug, permalink: anc.permalink} }
    end
  end
end

::Spree::V2::Storefront::TaxonSerializer.prepend Spree::V2::Storefront::TaxonSerializerDecorator
