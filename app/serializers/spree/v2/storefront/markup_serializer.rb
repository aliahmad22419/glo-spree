module Spree
  module V2
    module Storefront
      class MarkupSerializer < BaseSerializer
        set_type :markup

        attributes :name, :value

      end
    end
  end
end
