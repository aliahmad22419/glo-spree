module Spree
  module TaxonDecorator
    def self.prepended(base)
      base.enum banner_position: {
        top: 0,
        centre: 1,
        bottom: 2,
        hide: 3
      }
      base.friendly_id :friendly_permalink, slug_column: :slug, use: [:history, :scoped], scope: :id

      base.scope :not_vendor, -> { where("vendor_id IS NULL") }
      base.scope :visible_to_vendors, -> { where(hide_from_vendors: false) }

      base.has_one :image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
      base.after_save :update_image
      base.has_many :visible_to_vendors,-> { where hide_from_vendors: false }, foreign_key: "parent_id", class_name: 'Spree::Taxon'

      base.belongs_to :vendor
      base.whitelisted_ransackable_attributes = %w[id slug permalink]
      base.before_save :set_vendor

      Spree::PermittedAttributes.taxon_attributes.push *[:hide_from_vendors, :description, :banner_position, :banner_text, :attachment_id]
      Spree::Api::ApiHelpers.taxon_attributes.push *[:hide_from_vendors, :description, :banner_position, :banner_text, :attachment_id]
    end

    def friendly_permalink
      name.parameterize
    end

    def update_image
      if attachment_id.present? && attachment_id != image&.id
        image&.destroy
        img = Spree::Image.find(attachment_id)
        img.update_attribute :viewable_id, self.id
      end
    end

    def should_generate_new_friendly_id?
      true
    end



    def set_vendor
      self.vendor_id = taxonomy&.vendor_id
    end
  end
end

::Spree::Taxon.prepend Spree::TaxonDecorator if ::Spree::Taxon.included_modules.exclude?(Spree::TaxonDecorator)
