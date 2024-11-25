module Spree
  module Api
    module V2
      module Storefront
        class ProductBatchesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_parent_product, only: :create

          def create
            product_batch = @parent_product.product_batches.new product_batch_params
            if product_batch.save
              render json: product_batch, status: :created
            else
              render_error_payload(failure(product_batch).error)
            end
          end
          
          private
          def product_batch_params
            params.require(:product_batch).permit(:product_name, :product_quantity, :product_id, :product_price, option_type_ids: [],
              variants: [:quantity, :price, :sku, :rrp, :unit_cost_price, :barcode_number, option_value_ids: []],
              batch_schedule_attributes: [:start_date, :end_date, :interval, :time_zone, :step_count, week_days: [], month_dates: []])
          end

          def set_parent_product
            @parent_product = Product.find_by('spree_products.id = ?', params[:product_batch][:product_id])
            render json: { error: "Daily Stock Product Not Found." }, status: 404 unless @parent_product&.daily_stock?
          end

        end
      end
    end
  end
end