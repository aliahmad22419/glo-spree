class HistoryLog < ApplicationRecord
  belongs_to :loggable, :polymorphic => true
  belongs_to :creator, class_name: "Spree::User"

  validates :kind, :history_notes, :platform, :creator_id, presence: true
  validates :creator_email, presence: true, email: true
end
