module Spree
  module V2
    module Storefront
      class ImageSerializer < BaseSerializer
        set_type :image

        attributes :viewable_type, :viewable_id, :attachment_file_name, :base_image, :thumbnail, :small_image, :position, :sort_order, :alt, :sort_order_info_product

        attribute :styles do |object, params|
          add_size = ""
          if object.viewable_type == "Spree::Variant"
            store = params[:store]
            add_size = store.max_image_width.to_s + "x" + store.max_image_height.to_s + ">" if store.present?
          end
          object.styles(add_size)
        end
      end
    end
  end
end
