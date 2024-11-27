module Spree::Promotion::Rules::UserDecorator
  def user_ids_string=(s)
    self.user_ids = s.to_s.split(',').map(&:strip)
  end

  # eligible method is not used earlier so commented
  # def eligible?(order, _options = {})
  #   # get users from all stores of client with same email
  #   client_store_ids = promotion.client.stores.ids
  #   store_users = Spree::User.where(store_id: client_store_ids).joins(:spree_roles)
  #                            .where(email: order.user.email, spree_roles: { name: 'customer' }).uniq
  #   users.include?(order.user)
  #   store_users.include?(order.user)
  # end
end
Spree::Promotion::Rules::User.prepend Spree::Promotion::Rules::UserDecorator
