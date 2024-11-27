module Spree
  class Answer < Spree::Base
    belongs_to :question, :class_name => 'Spree::Question'
    after_save :send_email_to_customer

    def send_email_to_customer
      Spree::GeneralMailer.send_email_to_customer(self).deliver_now if question.present? && question.guest_email.present?
    end

  end
end
