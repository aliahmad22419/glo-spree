module Spree
  class HtmlPage < Spree::Base
    belongs_to :store, :class_name => 'Spree::Store'
    has_one :html_layout , :class_name => 'Spree::HtmlLayout', dependent: :destroy
    has_many :publish_html_layouts , :class_name => 'Spree::PublishHtmlLayout', dependent: :destroy
  end
end
  