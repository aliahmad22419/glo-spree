module Spree
  module Api
    module V2
      module Storefront
        module TaxonsControllerDecorator
          def self.prepended(base)
            before_action :require_spree_current_user, only: [ :get_dropdown_data ]
          end

          def breadcrums
            render_serialized_payload { serialize_resource(get_taxon_from_permalink, Spree::V2::Storefront::TaxonSerializer) }
          end

          def get_dropdown_data
            taxons = current_client.taxons.not_vendor.select('id, name, lft, rgt').map{|t| {id: t.id,pretty_name: t.pretty_name}}
            render json: { taxons: taxons }, status: 200
          end

          private

          def get_taxon_from_permalink
            storefront_current_client.taxons.where(permalink: params[:permalink]).first
          end

          def resource
            scope.find_by(slug: params[:id]) || scope.find_by(id: params[:id])
          end
        end
      end
    end
  end
end

::Spree::Api::V2::Storefront::TaxonsController.prepend(Spree::Api::V2::Storefront::TaxonsControllerDecorator)

