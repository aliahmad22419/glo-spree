module Spree
  module Api
    module V2
      module Storefront
        class WishedProductsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          # before_action :set_wishlist, only: [:create]
          before_action :set_wishlist_product, only: [:update, :destroy]

          def create
            variant_id = Spree::Product.find_by(id: params[:wished_product][:variant_id]).master.id
            params[:wished_product][:variant_id] = variant_id
            wished_product = Spree::WishedItem.new(wished_product_attributes)
            @wishlist = @spree_current_user.wishlists.last
            if @wishlist.include? params[:wished_product][:variant_id]
              wished_product = @wishlist.wished_items.detect { |wp| wp.variant_id == params[:wished_product][:variant_id].to_i }
              render_serialized_payload { success({already_added: true}).value  }
            else
              wished_product.wishlist = @wishlist
              wished_product.save
              render_serialized_payload { success({wished_product_id: wished_product.id}).value  }
            end
          end

          def update
            if @wished_product.update(wished_product_attributes)
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@wished_product).error)
            end
          end

          def destroy
            if @wished_product.destroy
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@wished_product).error)
            end
          end

          private
  
            def set_wishlist
              @wishlist = @spree_current_user.wishlists.find_by(id: params[:wishlist_id])
            end

            def set_wishlist_product
              @wished_product = Spree::WishedItem.find_by(id: params[:id])
              return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @wished_product
            end
            
            def wished_product_attributes
              params.require(:wished_product).permit(:variant_id, :wishlist_id, :remark, :quantity)
            end
          
        end
      end
    end
  end
end
