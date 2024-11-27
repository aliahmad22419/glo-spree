module Spree
  module PromotionRuleDecorator

  end
end
::Spree::PromotionRule.prepend Spree::PromotionRuleDecorator if ::Spree::PromotionRule.included_modules.exclude?(Spree::PromotionRuleDecorator)
