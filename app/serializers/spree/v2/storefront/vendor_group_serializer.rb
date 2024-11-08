module Spree
  module V2
    module Storefront
      class VendorGroupSerializer < BaseSerializer
        set_type :vendor_group

        attributes :inventories do |object|
          object.linked_inventories
        end

        attributes :vendors do |object|
            object.vendors&.pluck(:name, :slug, :email, :id)
        end
 
      end
    end
  end
end
