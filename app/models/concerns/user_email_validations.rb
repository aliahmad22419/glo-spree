# Email Validations transformed
module UserEmailValidations
  extend ActiveSupport::Concern

  included do
    # attr_accessor :spree_role
    validate :email_uniqueness_requirements_are_met

    # clear all validations for email
    _validators.reject!{ |key, value| key == :email }
    _validate_callbacks.each do |callback|
      callback.filter.attributes.reject! { |key| key == :email } if callback.filter.respond_to?(:attributes)
    end

    # email validations
    validates :email, presence: true, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\W]+\z/, message: "format is invalid" }
    # validates :store_id, presence: true, if: Proc.new { |user| user.spree_roles.last.name == "customer" rescue false }
  end

  def email_uniqueness_requirements_are_met
    spree_role = self.spree_roles.last
    users = (if Spree::User.const_get(:FULFILMENT_ROLES).include?(spree_role&.name)
              Spree::User.joins(:spree_roles).where(spree_roles: { name: Spree::User.const_get(:FULFILMENT_ROLES) })
            else
              spree_role.users if spree_role.present?
            end)&.where("email = ? AND spree_users.id <> ?", email, (id||0))
    users = users&.where(store_id: store_id).present? if spree_role&.name == "customer"
    errors.add(:email, "has already been taken" ) unless users.blank?
  end

  # for spree_role in Spree::Role.all.map(&:name).uniq do
  #   define_method "valid_#{spree_role}_email?" do
  #   end
  # end

  # def valid_admin_email?
  #   admins = spree_role.users.where("spree_users.id <> ? AND spree_users.email = ?", id, email)
  #   errors.add(:email, "has already been taken" ) unless admins.blank?
  # end
  #
  # def valid_client_email?
  #   clients = spree_role.users.where("spree_users.id <> ? AND spree_users.email = ?", id, email)
  #   errors.add(:email, "has already been taken" ) unless clients.blank?
  # end
  #
  # def valid_vendor_email?
  #   vendors = spree_role.users.where("spree_users.id <> ? AND spree_users.email = ?", id, email)
  #   errors.add(:email, "has already been taken" ) unless vendors.blank?
  # end
  #
  # def valid_customer_email?
  #   customers = spree_role.users.where.not(id: id)
  #   customers = customers.where(email: email)
  #   customers = customers.where(store_id: store_id)
  # end
end
