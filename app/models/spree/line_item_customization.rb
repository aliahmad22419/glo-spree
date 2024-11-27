module Spree
  class LineItemCustomization < Spree::Base
    include ActionView::Helpers::TextHelper
    has_one :image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
    belongs_to :line_item, class_name: 'Spree::LineItem'
    belongs_to :customization, class_name: 'Spree::Customization'

    VALUE_FIELDS = ["Area", "Field", "Multiple Select", "Date"]
    LONG_FIELDS = ["Area", "Field"]

    def save_image cust_value
      img = Spree::Image.find_by('spree_assets.id = ?', cust_value)
      self.image = img if img .present?
    end

    def text
      return image&.attachment_file_name if field_type == "File"
      return value if VALUE_FIELDS.include?(field_type)
      title
    end

    def to_s texted=false
      return "#{name} - #{sku} " unless texted
      "#{name} - #{sku} - #{text}"
    end

    def print_next_line
      text = VALUE_FIELDS.include?(field_type) ? value : title
      word_wrap(text, line_width: 50)
    end
  end
end
