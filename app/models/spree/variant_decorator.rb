
module Spree
  module VariantDecorator

    def self.prepended(base)
      base.include InventoryCallbacks
      base.include Spree::Webhooks::HasWebhooks

      base._validators.delete(:sku)
      base._validate_callbacks.each do |callback|
        if callback.filter.respond_to? :attributes
          callback.filter.attributes.delete :sku
        end
      end

      base.has_one :vendor_group, through: :vendor
      base.belongs_to :linked_inventory
      base.scope :non_linked, -> (inventory_id=nil){ where(linked_inventory_id: [inventory_id.presence, nil].uniq).order(placeholder: :desc) }
      base.scope :track_inventory_enabled, -> { where(track_inventory: true) }
      base.scope :linked_except, -> (inventory_id){ where("linked_inventory_id IS NOT NULL AND linked_inventory_id != ?", inventory_id)}
      base.scope :unarchived, -> { where(archived: false) }

      base.scope :for_currency_and_available_price_amount, ->(currency = nil) do
        currency ||= Spree::Config[:currency]
        joins(:prices).where('spree_prices.currency = ?', currency).where('spree_prices.amount IS NOT NULL').distinct
      end

      base.after_create :generate_sku, if: :is_master
      base.after_save :set_placeholder
      base.delegate :linked, to: :product

      Spree::PermittedAttributes.variant_attributes.push *[:rrp]
    end

    def price_with_delivery_charges store, currency=nil
      @store = store
      return 0 if price.blank?

      price + product.delivery_charges(store)
    end

    def tax_category
      if self[:tax_category_id].nil?
        product.tax_category
      else
        product.client.tax_categories.find(self[:tax_category_id])
      end
    end

    def email_thumbnail
      if images.present?
        img =  images.find_by(base_image: true)
        img ||= images.reorder(sort_order: :desc).first
        img.active_storge_url(img&.attachment)
      end
    end

    def image_urls
      default_img = self.images&.sort_by { |i| [i.sort_order, i.id] }&.reverse.first
      return self&.product&.image_urls unless default_img&.present?

      base_img = self.images&.detect(&:base_image)
      small_img = self.images&.detect(&:small_image)
      thumbnail_img = self.images&.detect(&:thumbnail)
      data = {
        base: base_img ? base_img.styles[3][:url] : nil,
        small: small_img ? small_img.styles[3][:url] : nil,
        thumbnail: thumbnail_img ? thumbnail_img.styles[3][:url] : nil,
        default: default_img ? default_img.styles[3][:url] : nil
      }
    end

    private
      def set_placeholder
        self.update_column(:placeholder, self.options_text.presence || self.sku)
      end

      def generate_sku
        self.sku = "#{product.id}".rjust(6, "0")
      end

      def check_price
        if price.nil? && Spree::Config[:require_master_price]
          return errors.add(:base, :no_master_variant_found_to_infer_price)  unless product&.master
          return errors.add(:base, :must_supply_price_for_variant_or_master) if self == product.master

          self.price = product.master.price
        end
        if price.present? && currency.nil?
          self.currency = Spree::Config[:currency]
        end
      end

      def set_cost_currency
        self.cost_currency = Spree::Config[:currency] if cost_currency.blank?
      end
  end
end

::Spree::Variant.prepend Spree::VariantDecorator if ::Spree::Variant.included_modules.exclude?(Spree::VariantDecorator)
