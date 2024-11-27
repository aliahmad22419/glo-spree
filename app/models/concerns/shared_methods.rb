module SharedMethods
  extend ActiveSupport::Concern
  
  included do
    before_destroy :prevent_record_deletion, prepend: true
  end

  private

  def prevent_record_deletion
    raise "Being part of completed orders, can't delete #{self.class.name.demodulize.downcase}." unless is_tangible_item?
  end

  # Check if record does not belongs to completed order
  def is_tangible_item?
    return incomplete_order_line_items.where(variant_id: self.id).none? if self.class.name.eql?('Spree::Variant')
    return incomplete_order_line_items.where(variant_id: self.variants_including_master_ids).none? if self.class.name.eql?('Spree::Product')
    return !self.order.complete? if self.class.name.eql?('Spree::LineItem')

    return true
  end

  def incomplete_order_line_items
    Spree::LineItem.joins(:order).where.not(spree_orders: {completed_at: nil})
  end
end