module Spree
  module V2
    module Storefront
      class ExchangeRateSerializer < BaseSerializer
        set_type :exchnage_rate

        attributes :name, :value

      end
    end
  end
end
