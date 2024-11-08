module Spree
  module V2
    module Storefront
      class RedirectSerializer < BaseSerializer
        attributes :type_redirect, :from, :to, :store_id
      end
    end
  end
end
