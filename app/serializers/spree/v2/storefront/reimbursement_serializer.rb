module Spree
  module V2
    module Storefront
      class ReimbursementSerializer < BaseSerializer
        attributes :status, :total

        attributes :currency do |object|
            object&.order&.currency
        end

        attributes :order_number do |object|
            object&.order&.number
        end
      end
    end
  end
end
