module Spree
  module Api
    module V2
      module Storefront
        class VariantsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :set_store, only: [:index]

          def index
            if params[:line_item_id].present?
              product_id = Spree::LineItem.find_by('spree_line_items.id = ?', params[:line_item_id]).product.id
              variants = Spree::Variant.where(product_id: product_id, is_master: false)
              variants = variants.select{ |variant| variant.in_stock? }
              render_serialized_payload { serialize_collection(variants) }
            end
          end

          def destroy
            @variant = Variant.find_by('spree_variants.id = ?', params[:id])
            if @variant.destroy
              flash[:success] = Spree.t('notice_messages.variant_deleted')
            else
              flash[:error] = Spree.t('notice_messages.variant_not_deleted', error: @variant.errors.full_messages.to_sentence)
            end
    
            respond_with(@variant) do |format|
              format.html { redirect_to admin_product_variants_url(params[:product_id]) }
              format.js { render_js_for_destroy }
            end
          rescue Exception => e
            render json: { error: e.message }, status: :unprocessable_entity
          end

          private

          def serialize_collection(collection)
            Spree::V2::Storefront::VariantRefundSerializer.new(
              collection,
              { params: {default_currency: params[:currency], store: @store} }
            ).serializable_hash
          end

          def set_store
            @store ||= Spree::Store.find_by('spree_stores.id = ?', params[:store_id])
          end
        end
      end
    end
  end
end
