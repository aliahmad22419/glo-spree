
module Spree
  module Admin
    module TaxonsControllerDecorator
      private

      def load_taxon
        @taxon = @taxonomy.taxons.find_by('spree_taxons.id = ?', params[:id])
      end

      def load_taxonomy
        @taxonomy = Spree::Taxonomy.friendly.find_by(id: params[:taxonomy_id])
      end
    end
  end
end

::Spree::Admin::TaxonsController.prepend Spree::Admin::TaxonsControllerDecorator if ::Spree::Admin::TaxonsController.included_modules.exclude?(Spree::Admin::TaxonsControllerDecorator)
