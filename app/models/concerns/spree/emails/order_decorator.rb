module Spree
  module Emails
    module OrderDecorator
      def deliver_order_confirmation_email
        if store.ses_emails
          SesEmailsDataWorker.perform_async(id, "order_confirmation_customer")
          SesEmailsDataWorker.perform_async(id, "order_confirmation_vendor")
        else
          Spree::OrderMailer.confirm_email(id).deliver_later
          Spree::OrderMailer.email_to_vendors(self)
        end
        Spree::OrderMailer.notify_balance_due(id).deliver_later if self.payment_state.eql?("balance_due")
        update_column(:confirmation_delivered, true)
        FinanceReportWorker.perform_in(45.seconds.from_now,self.store_id) if store.enable_finance_report && store.every_storefront_sale?
      end
    end
  end
end
