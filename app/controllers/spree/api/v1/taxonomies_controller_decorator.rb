module Spree
  module Api
    module V1
      module TaxonomiesControllerDecorator
        private

        def taxonomy
          @taxonomy ||= Spree::Taxonomy.accessible_by(current_ability, :show).friendly.find_by(id: params[:id])
        end
      end
    end
  end
end


::Spree::Api::V1::TaxonomiesController.prepend Spree::Api::V1::TaxonomiesControllerDecorator
