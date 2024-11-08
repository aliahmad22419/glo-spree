module Spree
  module V2
    module Storefront
      class PreferenceSerializer < BaseSerializer
        set_type :preference

        attributes :sported_currency do |record|
          record.value
        end
      end
    end
  end
end
