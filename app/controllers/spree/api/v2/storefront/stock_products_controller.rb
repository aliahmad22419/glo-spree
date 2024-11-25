module Spree
  module Api
    module V2
      module Storefront
        class StockProductsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:available_products]
          before_action :set_parent_product, only: [:available_products, :index]
          before_action :set_stock_product, only: [:update]

          def index
            stock_products = @parent_product.stock_products.order(:effective_date)
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            q = stock_products.untrashed.ransack(params[:q])
            render_serialized_payload { serialize_collection(q.result) }
          end

          def update
            @stock_product.attributes = stock_product_params
            if @stock_product.save
              render_serialized_payload { serialize_resource(@stock_product)  }
            else
              render_error_payload(failure(@stock_product).error)
            end
          end

          def available_products
            stock_products = @parent_product.stock_products.effective_at(params[:date]).order(:effective_date)
            render_serialized_payload { serialize_collection(stock_products) }
          end
        
          private
          def set_stock_product
            @stock_product = Spree::StockProduct.accessible_by(current_ability).find_by(id: params[:id])
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @stock_product
          end

          def set_parent_product
            @parent_product = Spree::Product.accessible_by(current_ability).find_by(id: params[:parent_product_id])
            render json: {error: "Daily Stock Product Not Found."}, status: 404 unless @parent_product&.daily_stock?
          end

          def stock_product_params
            params.require(:stock_product).permit(:name, :count_on_hand, :default_quantity, :pack_size, :disable_quantity, :minimum_order_quantity)
          end

          def serialize_collection(collection)
            default_currency = request.headers['X-Currency'] || collection.last&.vendor.try(:base_currency).try(:name) 
            Spree::V2::Storefront::StockProductSerializer.new(
              collection,
              meta: collection_meta(collection),
              include: resource_includes,
              params: {
                default_currency: default_currency,
                store: spree_current_store
              }
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::StockProductSerializer.new(resource).serializable_hash
          end

        end
      end
    end
  end
end
