module Spree
  module ReturnAuthorizationDecorator
    def currency
      order.nil? ? Spree::Config[:currency] : order.currency
    end
  end
end

::Spree::ReturnAuthorization.prepend Spree::ReturnAuthorizationDecorator if ::Spree::ReturnAuthorization.included_modules.exclude?(Spree::ReturnAuthorizationDecorator)
