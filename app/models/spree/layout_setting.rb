module Spree
  class LayoutSetting < Spree::Base
    FORBIDDEN_SET_PREFERENCES = [:custom_js]
    before_save :validate_custom_js, :validate_custom_css
    FONT_HASH = { "type" => "", "colorCode" => "", "size" => "" }
    # CUSTOM_JS_HASH = {"name" => "", "url" => "" }

    preference :primary_font, :string
    preference :secondary_font, :string
    preference :paragraph, :json, default: FONT_HASH
    preference :heading_1, :json, default: FONT_HASH
    preference :heading_2, :json, default: FONT_HASH
    preference :heading_3, :json, default: FONT_HASH
    preference :heading_4, :json, default: FONT_HASH
    preference :heading_5, :json, default: FONT_HASH
    preference :heading_6, :json, default: FONT_HASH
    preference :href_link, :json, default: FONT_HASH
    preference :href_link_active, :json, default: FONT_HASH
    preference :button, :json, default: FONT_HASH
    preference :button_active, :json, default: FONT_HASH
    preference :bg_color, :json, default: { "primary" => "", "secondary" => "" }
    preference :custom_js, :text, default: ""
    preference :custom_css, :text, default: ""
    preference :custom_js_url, :text, default: ""
    preference :custom_css_url, :text, default: ""
    preference :custom_js_links, :array, default: []

    belongs_to :store, class_name: 'Spree::Store'

     def validate_custom_js
      begin
        Terser.compile(self.preferred_custom_js&.html_safe)
      rescue => e
        errors.add(:base, "Invalid Js error: " + e.message)
        throw(:abort)
      end
    end

    def validate_custom_css
      begin
        Sass.compile(self.preferred_custom_css&.html_safe)
      rescue => e
        errors.add(:base, "Invalid Css error: " + e.message)
        throw(:abort)
      end
    end
  end
end
