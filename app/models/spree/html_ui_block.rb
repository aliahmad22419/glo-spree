module Spree
  class HtmlUiBlock < Spree::Base
    has_one :image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
    belongs_to :html_component, :class_name => 'Spree::HtmlComponent'
    has_many :html_links , -> { order(sort_order: :asc) }, as: :resource, dependent: :destroy
    accepts_nested_attributes_for :html_links, allow_destroy: true
    has_many :html_ui_block_sections , -> { order(position: :asc) }, dependent: :destroy, :class_name => 'Spree::HtmlUiBlockSection'
    accepts_nested_attributes_for :html_ui_block_sections, allow_destroy: true, reject_if: :all_blank

    # acts_as_list scope: :html_component

    after_save :update_image

    def update_image
      if gallery_image_id.present?
        image&.destroy
        temp_image = Spree::Image.find(gallery_image_id)
        img = Spree::Image.new(viewable_type: "Spree::HtmlUiBlock", attachment_file_name: temp_image.attachment_file_name, viewable_id: self.id)
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
  