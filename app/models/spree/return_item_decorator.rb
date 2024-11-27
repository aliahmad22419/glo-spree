
module Spree
  module ReturnItemDecorator
    def currency
      return_authorization.try(:currency) || Spree::Config[:currency]
    end
  end
end

::Spree::ReturnItem.prepend Spree::ReturnItemDecorator if ::Spree::ReturnItem.included_modules.exclude?(Spree::ReturnItemDecorator)
