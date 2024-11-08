module Spree
  module V2
    module Storefront
      class RefundSerializer < BaseSerializer
        attribute :id,:payment_id, :amount, :transaction_id, :created_at, :updated_at, :refund_reason_id, :reimbursement_id, :notes, :user_id, :state, :payment_refund_type

        attribute :csr_lead_email do |object|
         object.created_by.email
        end
      end
    end
  end
end
