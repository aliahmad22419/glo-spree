module Spree
  module Api
    module V2
      module Storefront
        class LinkedInventoriesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :set_vendor_group
          before_action :set_variants, only: [:create, :update]
          before_action :set_inventory, only: [:show, :update, :destroy]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            inventories = @vendor_group.linked_inventories.ransack(params[:q]).result.order("created_at DESC")
            render_serialized_payload { serialize_collection(collection_paginator.new(inventories, params).call) }
          end

          def create
            @linked_inventory = @vendor_group.linked_inventories.new(linked_inventory_params)
            if @linked_inventory.save
              render json: @linked_inventory, status: :created
            else
              render json: @linked_inventory.errors
            end
          end

          def destroy
            if @linked_inventory.destroy
              render json: @linked_inventory, status: 200
            else
              render json: @linked_inventory.errors
            end
          end

          def update
            @linked_inventory.update(linked_inventory_params)
            unless @linked_inventory.errors.any?
              render json: @linked_inventory, status: 200
            else
              render_error_payload(failure(@linked_inventory).error)
            end
          end

          def show
            master_variant = @linked_inventory.master_variant

            linked_inventory = {
              linked_inventory: @linked_inventory,
              master_product: master_variant&.product,
              linked_variants: @linked_inventory.variants.ids - [master_variant.id]
            }
            render json: { inventory: linked_inventory }
          end

          private

          def set_vendor_group
            @vendor_group = current_vendor&.vendor_group

            render json: {error: "Vendor Group not found"}, status: :not_found if @vendor_group.blank?
          end

          def set_variants
            @variants = Spree::Variant.track_inventory_enabled.where(id: inclusive_variant_ids)
          end

          def set_inventory
            @linked_inventory = @vendor_group.linked_inventories.find_by('spree_linked_inventories.id = ?', params[:id])

            render json: {error: "Linked Inventory not found"}, status: :not_found if @linked_inventory.blank?
          end

          def inclusive_variant_ids
            @variants_including_master ||= params[:linked_variant_ids] << params[:master_variant_id]
          end

          def linked_inventory_params
            params.require(:linked_inventory).permit(:id, :name, :quantity, :master_variant_id, :vendor_group_id).
              merge!(variant_ids: inclusive_variant_ids)
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::LinkedInventorySerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

        end
      end
    end
  end
end
