module InventoryCallbacks
  extend ActiveSupport::Concern
  
  included do
    before_destroy :prevent_record_deletion, prepend: true
    before_save :validate_linkage, prepend: true, if: :product_linked?
  end

  private
  
  def validate_linkage
    raise Spree.t(:linked_product_vendor_changed) if vendor_id_changed?
    raise Spree.t(:linked_product_changed) if linked_changed?
  end

  def prevent_record_deletion
    raise "Can't delete product linked with inventory." if linked_with_inventory?
  end

  def linked_with_inventory?
    product_linked? || variant_linked?
  end

  def variant_linked?
    is_a?(Spree::Variant) && self.linked_inventory_id.present?
  end

  # StockProduct neither be linked nor can change vendor,
  # so it depends on parent product
  def product_linked?
    (is_a?(Spree::Product) || self.type_of?('StockProduct')) &&
      master_or_variants.pluck(:linked_inventory_id).compact.present?
  end

end