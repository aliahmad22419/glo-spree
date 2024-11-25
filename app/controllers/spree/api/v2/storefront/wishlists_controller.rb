module Spree
  module Api
    module V2
      module Storefront
        class WishlistsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user

          before_action :set_wishlist, only: [:destroy, :show, :update, :edit]

          def index
            wishlists = @spree_current_user.wishlists
            render_serialized_payload { serialize_collection(wishlists) }
          end

          def show
            render_serialized_payload { serialize_resource(@wishlist) }
          end

          def user_wishlist
            render_serialized_payload { serialize_resource(@spree_current_user.wishlists.last) }
          end

          def create
            wishlist = @spree_current_user.wishlists.build(wishlist_params)
            if wishlist.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(wishlist).error)
            end
          end

          def update
            if @wishlist.update(wishlist_params)
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@wishlist).error)
            end
          end

          def destroy
            if @wishlist.destroy
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@wishlist).error)
            end
          end

          private

            def serialize_resource(resource)
              Spree::V2::Storefront::WishlistSerializer.new(resource, params: { default_currency: current_currency, store: spree_current_store }).serializable_hash
            end

            def serialize_collection(collection)
              Spree::V2::Storefront::WishlistSerializer.new(collection, params: { default_currency: current_currency, store: spree_current_store }).serializable_hash
            end

            def wishlist_params
              params.require(:wishlist).permit(:name, :is_default, :is_private)
            end

            # Isolate this method so it can be overwritten
            def set_wishlist
              @wishlist = @spree_current_user.wishlists.find_by(id: params[:id])
              return render json: { error: "Wishlist not found" }, status: :not_found unless @wishlist
            end
        end
      end
    end
  end
end
