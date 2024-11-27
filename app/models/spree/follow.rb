module Spree
  class Follow < Spree::Base
    belongs_to :follower, class_name: 'User'
    belongs_to :followee, class_name: 'User'

    validates :follower_id, uniqueness: { scope: :followee_id }
    validates :followee_id, uniqueness: { scope: :follower_id }

    scope :not_approved, -> { where.not(status: "approved") }
    scope :not_rejected, -> { where.not(status: "rejected") }
    scope :approved, -> { where(status: "approved") }

    after_create :send_email_to_vendor
    after_update :send_email_to_customer

    self.whitelisted_ransackable_attributes = %w[name status email]

    def send_email_to_vendor
      Spree::GeneralMailer.send_follow_request_to_vendor(name, self&.followee&.email,  self&.follower&.email, details).deliver_now
    end

    def send_email_to_customer
      Spree::GeneralMailer.send_follow_request_status_to_customer(name, self&.followee&.email,  self&.follower&.email, status).deliver_now
    end

  end
end
