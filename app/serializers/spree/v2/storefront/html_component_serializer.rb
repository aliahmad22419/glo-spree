module Spree
  module V2
    module Storefront
      class HtmlComponentSerializer < BaseSerializer
        attributes :id, :name, :position, :type_of_component, :heading, :no_of_images

        attribute :html_ui_blocks do |object|
          Spree::V2::Storefront::HtmlUiBlockSerializer.new(object.html_ui_blocks).serializable_hash
        end
      end
    end
  end
end