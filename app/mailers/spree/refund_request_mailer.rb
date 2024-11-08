module Spree
  class RefundRequestMailer < BaseMailer
    def send_refund_request_mail line_item, spree_customer_name
      @line_item = line_item
      @store = line_item&.store
      @spree_customer_name = spree_customer_name
      @variant_name = @line_item&.variant&.name
      mail(to: @line_item.vendor.email, subject: "Refund Requested against product: "+@variant_name)
    end

    def refund_accepted_mail reimbursement
      @reimbursement = reimbursement
      @store = reimbursement&.order&.store
      mail(to: @reimbursement&.order&.email, subject: "Refund Request accepted again Order No: "+@reimbursement&.order&.number)
    end
  end
end
