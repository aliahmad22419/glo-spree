module Spree
  class HtmlLayout < Spree::Base
    belongs_to :html_page, :class_name => 'Spree::HtmlPage'
    has_many :html_components , -> { order(position: :asc) }, dependent: :destroy,  :class_name => 'Spree::HtmlComponent'
    accepts_nested_attributes_for :html_components, allow_destroy: true, reject_if: :all_blank

  end
end
  