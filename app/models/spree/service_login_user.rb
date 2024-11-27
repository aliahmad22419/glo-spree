class Spree::ServiceLoginUser < Spree::User

  validates :name, presence: true
  validate :email_uniqueness_requirements_are_met, on: [:update, :create]

  self.whitelisted_ransackable_attributes = %w[name email is_enabled]
  self.whitelisted_ransackable_associations = %w[ clients ]

  has_and_belongs_to_many :clients, class_name: 'Spree::Client', join_table: 'spree_clients_service_login', foreign_key: 'service_login_sub_admin_id', association_foreign_key: 'client_id'
  has_many :sub_clients, class_name: 'Spree::User', foreign_key: 'service_login_user_id'

  default_scope { joins(:spree_roles).where(spree_roles: { name: "service_login_sub_admin" }) }

  scope :active_service_login_users, -> { where(is_enabled: true) }
  scope :archive_service_login_users, -> { where(is_enabled: false) }

  after_update :nullify_service_login_user_id

  private

  def nullify_service_login_user_id
    if saved_change_to_is_enabled?(from: true, to: false)
      sub_clients.update_all(service_login_user_id: nil, is_enabled: true)
    end
  end

  def email_uniqueness_requirements_are_met
    users = Spree::User.joins(:spree_roles).where(spree_roles: { name: Spree::User.const_get(:USER_ROLES) })&.where("email = ? AND spree_users.id <> ?", email, (id||0))
    errors.add(:email, "has already been taken" ) unless users.blank?
  end
end
