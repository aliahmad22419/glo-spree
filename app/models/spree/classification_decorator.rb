module Spree
  module ClassificationDecorator
    def self.prepended(base)
      base.clear_validators!
      base.acts_as_list scope: :taxon
      base.after_commit -> (obj) { obj.product.reindex }, if: :saved_change_to_position?

      base.belongs_to :store, class_name: 'Spree::Store'

      base.validates :taxon, :product, :store, presence: true
      # For #3494
      base.validates :taxon_id, uniqueness: { :scope => [:product_id, :store_id], message: :already_linked, allow_blank: true }
    end

    class << self
      def reindex_curation(reordered_ids)
        product_ids = where('spree_products_taxons.id IN (?)', reordered_ids).map(&:product_id).uniq
        ReindexProductsWorker.perform_async(product_ids)
      end
    end
  end
end

Spree::Classification.prepend Spree::ClassificationDecorator
