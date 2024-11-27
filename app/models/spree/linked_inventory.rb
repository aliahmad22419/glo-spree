module Spree
  class LinkedInventory < Spree::Base
    acts_as_paranoid

    belongs_to :vendor_group
    has_many :variants, ->{ where(track_inventory: true) }
    belongs_to :master_variant, class_name: 'Spree::Variant', foreign_key: :master_variant_id
    has_many :vendors, through: :vendor_group

    after_save :update_variants_stock_items, if: :quantity_previously_changed?
    after_destroy :delink_inventory_variants
    validates :vendor_group, :presence => true, uniqueness: { scope: %i[variants] }
    validates :quantity, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 2**31 - 1,
      only_integer: true
    }
    validate :validate_mapping

    self.default_ransackable_attributes = %w[name]

    def stock_items
      Spree::StockItem.where(variant_id: variants.ids)
    end

    private
    def delink_inventory_variants
      self.variants.update_all(linked_inventory_id: nil)
    end

    def update_variants_stock_items
      return if variants.blank?
      stock_items.update_all(count_on_hand: self.quantity)
      variants.map{ |variant| variant.product.update(count_on_hand: self.quantity) }
    end

    def validate_mapping
      errors.add(:linked_inventory, "has variants already linked") if self.variants.linked_except(self.id).any?
      errors.add(:linked_inventory, "has non linkable products") if self.variants.map(&:linked).any?(false)
      errors.add(:linked_inventory, "has products linked to other vendor groups") unless self.variants.map(&:vendor_group_id).all?(self.vendor_group_id)

      throw(:abort) if errors.any?
    end
  end
end