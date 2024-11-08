module Spree
  module V2
    module Storefront
      class OrderTagSerializer < BaseSerializer
        set_type :order_tag

        attributes :label_name, :intimation_email
      end
    end
  end
end
