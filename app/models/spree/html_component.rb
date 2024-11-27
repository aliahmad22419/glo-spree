module Spree
  class HtmlComponent < Spree::Base
    belongs_to :html_layout, :class_name => 'Spree::HtmlLayout' 
    belongs_to :publish_html_layout, :class_name => 'Spree::PublishHtmlLayout' 
    has_many :html_ui_blocks , -> { order(position: :asc) } , dependent: :destroy, :class_name => 'Spree::HtmlUiBlock'
    accepts_nested_attributes_for :html_ui_blocks, allow_destroy: true, reject_if: :all_blank
    # acts_as_list scope: :html_layout
    # after_create :add_multi_banner
    after_commit :flush_cache

    def flush_cache
      self.html_layout&.html_page&.store&.clear_home_cache(self.html_layout&.id)
    end

    def add_multi_banner
      if type_of_component == 'multi_banner'
        html_ui_blocks.create(title:'banner1')
        html_ui_blocks.create(title:'banner2')
     end
      footer =  html_layout&.html_components&.where(type_of_component: "footer")&.first
      if footer
        footer_position = footer&.position
        footer.update_column(:position, footer_position + 1)
      end
    end

  end
end
  