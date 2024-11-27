module Spree
  class Promotion
    module Rules
      module ProductDecorator
        def product_ids_string=(s)
          self.product_ids = s.to_s.split(',').map(&:strip)
        end
      end
    end
  end
end

::Spree::Promotion::Rules::Product.prepend Spree::Promotion::Rules::ProductDecorator
