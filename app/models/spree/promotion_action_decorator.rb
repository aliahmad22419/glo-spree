module Spree::PromotionActionDecorator
  protected
  def promo_applicable?(line_item)
    action = promotion.actions[0]
    return true unless action.exclude_sale_items

    !line_item.product.on_sale?
  end
end

::Spree::PromotionAction.prepend Spree::PromotionActionDecorator
