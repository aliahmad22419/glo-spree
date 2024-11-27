class EmailChange < ApplicationRecord
  belongs_to :updatable, :polymorphic => true
  belongs_to :user, class_name: "Spree::User", optional: true

  validates :previous_email, :next_email, presence: true, email: true
  validates :note, presence: true
  validate :check_same_email, if: Proc.new { user_id.present? }

  # using after create as update will never be called (assumption for now)
  after_commit :update_and_send_cards, if: Proc.new { user_id.present? }
  after_create :update_receipient_email
  scope :by_lead, -> { where.not(user_id: nil) } # only lead changed emails
  scope :latest, -> { order(created_at: :desc).first }

  def check_same_email
    updatable.errors.add(:previous_email, "cannot be same as next email.") if previous_email === next_email
  end

  def update_and_send_cards
    return unless self.updatable.respond_to?(:send_associated_emails, true)

    self.updatable.send(:send_associated_emails)
  end
  def update_receipient_email
    updatable.update(receipient_email: next_email) if updatable.has_attribute?("receipient_email")
  end
end
