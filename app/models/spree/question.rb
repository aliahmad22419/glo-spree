module Spree
  class Question < Spree::Base
    self.default_ransackable_attributes = %w[is_replied]
    # validates_presence_of :title, :order, :status, :heading, :content
    belongs_to :questionable, polymorphic: true
    belongs_to :vendor, :class_name => 'Spree::Vendor'
    belongs_to :product, :class_name => 'Spree::Product'
    belongs_to :store, :class_name => 'Spree::Store'
    has_one :answer, :class_name => 'Spree::Answer'
    after_save :send_email_to_vendor

    def send_email_to_vendor
      if self.questionable_type == "Spree::Order" && self.guest_email.blank?
        Spree::GeneralMailer.send_order_email_to_customer(questionable.email, store.mail_from_address, title, vendor&.client&.active_storge_url(vendor&.client&.logo), store, self).deliver_now
      elsif self.questionable_type == "Spree::Follow"
        Spree::GeneralMailer.send_request_question_to_follower(self).deliver_now
      else
        Spree::GeneralMailer.send_question_email_to_vendor(self).deliver_now
      end
    end

  end
end
