class Spree::BulkOrder < Spree::Base
  has_one :order, class_name: 'Spree::Order', :dependent => :destroy
  belongs_to :client, class_name: 'Spree::Client'
  belongs_to :user, class_name: 'Spree::User'

  has_one_attached :csv_file
  validates :user_id, :client_id, :state, presence: true

  before_destroy :prevent_destruction
  after_destroy -> { self.csv_file.purge_later }

  scope :pending_or_complete, -> { where(state: %w[payment confirm complete]) }

  delegate :id, :number, :state, :email, to: :order, prefix: :order

  self.whitelisted_ransackable_associations = %w[ order ]
  self.whitelisted_ransackable_attributes = %w[ order_number_or_order_email_cont order_store_name_cont ]


  private

  def prevent_destruction
      (
        errors.add(:base, I18n.t("spree.bulk_order.destroy", state: order.state))
        throw(:abort)
      ) unless %w[cart address delivery].include?(order.state)
  end
end
