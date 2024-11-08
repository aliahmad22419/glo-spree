# Spree::ReimbursementMailer.class_eval do
#   def reimbursement_email(reimbursement, resend = false)
#     @reimbursement = reimbursement.respond_to?(:id) ? reimbursement : Spree::Reimbursement.find(reimbursement)
#     @order = @reimbursement.order
#     @store = @order.store
#     subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
#     subject += "#{Spree::Store.current.name} #{Spree.t('reimbursement_mailer.reimbursement_email.subject')} ##{@order.number}"
#     mail(to: @order.email, cc: cc_store_recipients(@store), subject: subject)
#   end
# end

module Spree
  module ReimbursementMailerDecorator
    def reimbursement_email(reimbursement, resend = false)
      @reimbursement = reimbursement.respond_to?(:id) ? reimbursement : Spree::Reimbursement.find(reimbursement)
      @order = @reimbursement.order
      @store = @order.store
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{Spree::Store.current.name} #{Spree.t('reimbursement_mailer.reimbursement_email.subject')} ##{@order.number}"
      mail(to: @order.email, cc: cc_store_recipients(@store), subject: subject)
    end
  end
end


::Spree::ReimbursementMailer.prepend Spree::ReimbursementMailerDecorator
