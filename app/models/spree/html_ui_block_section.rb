module Spree
  class HtmlUiBlockSection < Spree::Base
    # acts_as_list scope: :html_ui_block

    belongs_to :html_ui_block, :class_name => 'Spree::HtmlComponent'
    has_one :image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
    has_many :html_links , -> { order(sort_order: :asc) }, as: :resource, dependent: :destroy
    accepts_nested_attributes_for :html_links, allow_destroy: true, reject_if: :all_blank

    after_save :delete_links
    after_save :update_image

    def delete_links
      html_links&.destroy_all if type_of_section == "image"
    end

    def update_image
      if gallery_image_id.present?
        image&.destroy
        temp_image = Spree::Image.find(gallery_image_id)
        img = Spree::Image.new(viewable_type: "Spree::HtmlUiBlockSection", attachment_file_name: temp_image.attachment_file_name, viewable_id: self.id)
        img.attachment.attach(temp_image&.attachment.blob)
        img.save!
        self.update(attachment_id:nil, gallery_image_id:nil)
      elsif attachment_id.present? && attachment_id != image&.id
        image&.destroy
        img = Spree::Image.find(attachment_id)
        img.update_attribute :viewable_id, self.id
      end
    end

  end
end
  