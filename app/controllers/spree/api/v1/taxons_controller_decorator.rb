module Spree
  module Api
    module V1
      module TaxonsControllerDecorator

        def index
          @taxons = if taxonomy
                  taxonomy.root.children
                elsif params[:ids]
                  Spree::Taxon.includes(:children).accessible_by(current_ability).where('spree_taxons.id IN (?)', params[:ids].split(','))
                else
                  if params[:vendor_management]
                    Spree::Taxon.not_vendor.includes(:children).accessible_by(current_ability).order(:taxonomy_id, :lft)
                  else
                    Spree::Taxon.includes(:children).accessible_by(current_ability).where(vendor_id: nil).order(:taxonomy_id, :lft)
                  end
                end
          @taxons = @taxons.ransack(params[:q]).result
          @taxons = @taxons.page(params[:page]).per(params[:per_page])
          respond_with(@taxons)
        end

        def create
          authorize! :create, Spree::Taxon
          @taxon = Spree::Taxon.new(taxon_params)
          taxonomy = Spree::Taxonomy.friendly.find_by(id: params[:taxonomy_id])
          @taxon.taxonomy_id = taxonomy.id

          if taxonomy.nil?
            @taxon.errors.add(:taxonomy_id, I18n.t('spree.api.invalid_taxonomy_id'))
            invalid_resource!(@taxon) and return
          end

          @taxon.parent_id = taxonomy.root.id unless params[:taxon][:parent_id]

          if @taxon.save
            respond_with(@taxon, status: 201, default_template: :show)
          else
            invalid_resource!(@taxon)
          end
        end

        def products
          # Returns the products sorted by their position with the classification
          # Products#index does not do the sorting.
          taxon = Spree::Taxon.find_by('spree_taxons.id = ?', params[:id])
          @products = taxon.products.ransack(params[:q]).result
          @products = @products.page(params[:page]).per(params[:per_page] || 500)
          render 'spree/api/v1/products/index'
        end

        private

        def taxonomy
          if params[:taxonomy_id].present?
            @taxonomy ||= Spree::Taxonomy.accessible_by(current_ability, :show).friendly.find_by(id: params[:taxonomy_id])
          end
        end

        def taxon
          @taxon ||= taxonomy.taxons.accessible_by(current_ability, :show).friendly.find_by(id: params[:id])
        end

      end
    end
  end
end

::Spree::Api::V1::TaxonsController.prepend Spree::Api::V1::TaxonsControllerDecorator
