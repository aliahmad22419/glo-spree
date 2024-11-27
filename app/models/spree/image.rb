module Spree
  class Image < Asset
    include Configuration::ActiveStorage
    include Rails.application.routes.url_helpers

    self.whitelisted_ransackable_attributes = %w[attachment_file_name]

    # In Rails 5.x class constants are being undefined/redefined during the code reloading process
    # in a rails development environment, after which the actual ruby objects stored in those class constants
    # are no longer equal (subclass == self) what causes error ActiveRecord::SubclassNotFound
    # Invalid single-table inheritance type: Spree::Image is not a subclass of Spree::Image.
    # The line below prevents the error.
    self.inheritance_column = nil

    def styles more_size = ""
      auto_styles = self.class.styles
      auto_styles[:product_detail] = more_size if more_size.present?
      self.class.styles.map do |_, size|
        #For svg,avif,webp variants methods is not applied. it gives error so svg , avif and webp  files will be uploaded without variants.
        if attachment&.blob&.content_type != "application/octet-stream" && attachment&.blob&.content_type != "image/svg" && attachment&.blob&.content_type != "image/svg+xml" && attachment.content_type != "video/mp4"
          width, height = size[/(\d+)x(\d+)/]&.split('x')
          {
            url: rails_public_blob_url(attachment.variant(resize: size), only_path: true),
            width: width,
            height: height
          }
        elsif attachment.content_type == "video/mp4"
          width, height = size[/(\d+)x(\d+)/]&.split('x')
          {
            url: rails_public_blob_url(attachment, only_path: true),
            width: width,
            height: height
          }
        end
      end
    end

    def duplicate(viewable)
      attrs = attributes.except('id', 'updated_at', 'created_at', 'viewable_id', 'viewable_type')
      img = Spree::Image.new(attrs)
      img.viewable_id = viewable.id
      img.attachment.attach(attachment.blob)
      img.save!
      img.update(viewable_type: viewable&.class&.name)
    end

    def duplicate_without_viewable
      attrs = attributes.except('id', 'updated_at', 'created_at', 'viewable_id', 'viewable_type')
      img = Spree::Image.new(attrs)
      img.attachment.attach(attachment.blob)
      img.viewable_type = 'Spree::Variant'
      img.save!
      img
    end
  end
end
