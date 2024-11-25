module Spree
  module Api
    module V2
      module Storefront
        class TaxCategoriesController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :set_tax_category, only: [:show, :update, :destroy]
          before_action :check_permissions

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            tax_categories = Spree::TaxCategory.accessible_by(current_ability, :index).ransack(params[:q]).result.order("id DESC")
            tax_categories = collection_paginator.new(tax_categories, params).call
            render_serialized_payload { serialize_collection(tax_categories) }
          end

          def show
            render_serialized_payload { serialize_resource(@tax_category) }
          end

          def update
            if @tax_category.update(tax_categories_params)
              render_serialized_payload { serialize_resource(@tax_category) }
            else
              render_error_payload(failure(@tax_category).error)
            end
          end

          def destroy_multiple
            tax_categories = Spree::TaxCategory.where('spree_tax_categories.id IN (?)', JSON.parse(params[:ids]))
            if tax_categories.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(tax_categories).error)
            end
          end

          def create
              tax_categories = current_client.tax_categories.new(tax_categories_params)
              if tax_categories.save
                render_serialized_payload { serialize_resource(tax_categories) }
              else
                render_error_payload(failure(tax_categories).error)
              end
          end

          def destroy
            if @tax_category.destroy
              render_serialized_payload { serialize_resource(@tax_category) }
            else
              render_error_payload(failure(@tax_category).error)
            end
          end

          private
          def serialize_collection(collection)
            Spree::V2::Storefront::TaxCategoriesSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::TaxCategoriesSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_tax_category
            @tax_category = Spree::TaxCategory.accessible_by(current_ability).find_by('spree_tax_categories.id = ?', params[:id])
            return render json: { error: "Tax Category not found" }, status: 403 unless @tax_category
          end

          def tax_categories_params
            params.require(:tax_category).permit(:name, :description, :is_default, :tax_code)
          end

        end
      end
    end
  end
end
