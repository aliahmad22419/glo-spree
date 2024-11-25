module Spree
  module Api
    module V2
      module Storefront
        class VendorGroupsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :set_vendor_group
          before_action :require_vendors_in_group, :set_inventory, only: [:products]

          def products
            @collection = @vendor_group.products.order('LOWER(spree_products.name)')
            @linkable_variants = collections_variants
            render json: products_json_collection
          end

          private
          def require_vendors_in_group
            render json: {error: "Vendor must exists in vendor group"}, status: :not_found if @vendor_group&.vendors.blank?
          end

          def set_vendor_group
            @vendor_group = current_vendor&.vendor_group
            render json: {error: "Vendor group Not Found"}, status: :not_found if @vendor_group.blank?
          end

          def set_inventory
            @inventory = @vendor_group.linked_inventories.find_by(id: params[:inventory_id])
          end

          def collections_variants
            Spree::Variant.where("product_id IN (?)", @collection.pluck(:id)).non_linked(params[:inventory_id]).map { |variant| {
              id: variant.id,
              is_master: variant.is_master,
              product_id: variant.product.id,
              name: "#{variant.placeholder} (#{variant.product.name})"
            }}
          end

          def products_json_collection
            @collection.map { |product| {
              id: product.id,
              name: product.name,
              linked_variants: @inventory.present? ? @inventory.variants.ids : [] ,
              variants: product.master_or_variants.non_linked(params[:inventory_id]).map { |variant| {
                id: variant.id,
                name: "#{variant.placeholder} (#{variant.product.name})",
                is_master: variant.is_master,
                non_linked_variants: linkable_variants_excluding(product)
              }}
            }}
          end

          def linkable_variants_excluding(product)
            @linkable_variants.filter{ |variant| variant[:product_id] != product.id }
          end

        end
      end
    end
  end
end
