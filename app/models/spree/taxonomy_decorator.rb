module Spree::TaxonomyDecorator
  def self.prepended(base)
    base.belongs_to :store
    base.belongs_to :vendor

    base.scope :by_store, -> (store) { where(store_id: store) }
    base.extend FriendlyId
    base.friendly_id :slug_candidates, use: :history
    # friendly_id :slug_candidates, use: [:slugged, :history]
    # before_validation :normalize_slug, on: :save
  end
  def slug_candidates
    name.parameterize
  end

  def normalize_slug
    self.slug = name.parameterize # normalize_friendly_id(slug)
  end
end


::Spree::Taxonomy.prepend(Spree::TaxonomyDecorator)
