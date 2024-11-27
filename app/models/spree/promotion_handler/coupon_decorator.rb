module Spree::PromotionHandler::CouponDecorator
  def initialize(order)
    @order = order
    @client = @order.store.client
  end

  def apply
    if order.coupon_code.present?
      if promotion.present? && promotion.actions.exists?
        action = promotion.actions[0]
        if action.respond_to?(:calculator) && action.calculator.instance_of?(Spree::Calculator::RelatedProductDiscount)
          set_error_code :coupon_code_unknown_error
        else
          handle_present_promotion
        end
      elsif Spree::Promotion.with_coupon_code(order.coupon_code).try(:expired?)
        set_error_code :coupon_code_expired
      else
        set_error_code :coupon_code_not_found
      end
    else
      set_error_code :coupon_code_not_found
    end
    self
  end

  def promotion
    @promotion ||= @client.promotions.active.includes(:promotion_rules, :promotion_actions)
                                            .with_coupon_code(order.coupon_code)
  end
end

Spree::PromotionHandler::Coupon.prepend Spree::PromotionHandler::CouponDecorator
