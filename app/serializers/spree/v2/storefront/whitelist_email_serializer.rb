module Spree
  module V2
    module Storefront
      class WhitelistEmailSerializer < BaseSerializer
        set_type :whitelist_email
        
        attributes :email, :status
      end
    end
  end
end