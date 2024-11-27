module Spree::Promotion::Rules::TaxonDecorator
  def taxon_ids_string=(s)
    ids = s.to_s.split(',').map(&:strip)
    self.taxons = Spree::Taxon.find(ids)
  end

  def actionable?(line_item)
    taxon_product_ids.include? line_item.variant.product_id
  end

  private
  # All taxons in an order
  def order_taxons(order)
    Spree::Taxon.joins(products: { variants_including_master: :line_items }).where(spree_line_items: { order_id: order.id }).distinct
  end

  def taxon_product_ids
    Spree::Product.joins(:taxons).where(spree_taxons: { id: taxons.pluck(:id) }).pluck(:id).uniq
  end
end

Spree::Promotion::Rules::Taxon.prepend Spree::Promotion::Rules::TaxonDecorator