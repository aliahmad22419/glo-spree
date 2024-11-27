module Spree::PromotionHandler::FreeShippingDecorator
  def initialize(order)
    @order = order
    @order_promo_ids = order.promotions.pluck(:id)
    @client = @order.store.client
  end

  private

  def promotions
    @client.promotions.active.where(
      id: Spree::Promotion::Actions::FreeShipping.pluck(:promotion_id),
      path: nil
    )
  end
end

::Spree::PromotionHandler::FreeShipping.prepend Spree::PromotionHandler::FreeShippingDecorator
