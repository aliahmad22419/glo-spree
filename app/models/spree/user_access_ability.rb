class Spree::UserAccessAbility
  include CanCan::Ability

  def initialize(user)
    if user.respond_to?(:has_spree_role?) && user.has_spree_role?('client')
      @client_id = user.client.id
      can :manage, Spree::Product, client_id: @client_id
      can :manage, Spree::StockProduct, client_id: @client_id
      cannot :manage, Spree::BulkOrder
      can :manage, Spree::BulkOrder, client_id: @client_id, state: %w[payment confirm complete]
      can [:create_sub_client, :create_fd_user], Spree::User
      givex_cards_permissions
      ts_cards_permissions(user)
      cannot :manage, Spree::Redirect
      can :manage, Spree::Redirect, store_id: user.client.store_ids
    elsif user.respond_to?(:has_spree_role?) && user.has_spree_role?('sub_client')
      cannot :manage, Spree::BulkOrder
      can :manage, Spree::BulkOrder,state: %w[payment confirm complete], order: { store_id: user.allow_store_ids }
      @client_id = user.client.id
      sub_client_givex_cards(user)
      sub_client_ts_cards(user)
      sub_client_users_ability(user)
      cannot :manage, Spree::Redirect
      can :manage, Spree::Redirect, store_id: user.allow_store_ids.map(&:to_i)
    elsif user.respond_to?(:has_spree_role?) && user.has_spree_role?('vendor')
      @client_id = user&.vendors&.first&.client&.id
      can :manage, Spree::StockProduct, client_id: @client_id
      can :manage, Spree::Product, client_id: @client_id
      cannot :create_sub_client, Spree::User
      vendor_store_ability
    elsif user.respond_to?(:has_spree_role?) && (user.has_spree_role?("fulfilment_admin") || user.has_spree_role?("fulfilment_super_admin"))
      fulfilment_team_admin_orders
      fulfilment_team_admin_zones
      fulfilment_team_admin_users(user.id)
      can :create_sub_client, Spree::User
    elsif user.respond_to?(:has_spree_role?) && user.has_spree_role?("fulfilment_user")
      fulfilment_team_users_orders(user)
      fulfilment_user(user)
    elsif user.respond_to?(:has_spree_role?) && user.has_spree_role?("customer_support") && user.lead?
      customer_support_lead
    elsif user.respond_to?(:has_spree_role?) && user.has_spree_role?("front_desk")
      front_desk_ability
    elsif user.respond_to?(:has_spree_role?) && user.has_spree_role?("service_login_sub_admin")
      cannot :manage, Spree::User
      cannot :manage, Spree::ServiceLoginUser
      can :show, Spree::ServiceLoginUser, id: user.id
      can :update, Spree::ServiceLoginUser, id: user.id
    end
  end

  private

  def sub_client_users_ability(user)
    cannot :manage, Spree::User
    can [:create_fd_user, :create], Spree::User, spree_roles: { name: 'front_desk' }
    can [:index, :show, :destroy, :update], Spree::User, client_id: @client_id, spree_roles: { name: 'front_desk' }
    if user.can_manage_sub_user
      can [:create_sub_client, :import_creation], Spree::User, spree_roles: { name: 'sub_client' }
      can [:index, :show, :update], Spree::User, client_id: @client_id, spree_roles: { name: 'sub_client' }
    end
    cannot [:show, :update, :destroy, :index], Spree::User, id: user.id
  end

  def givex_cards_permissions
    cannot :read, Spree::GivexCard
    can :manage, Spree::GivexCard, client_id: @client_id
    can :create, Spree::GivexCard
  end

  def ts_cards_permissions(user)
    can :update_status, Spree::TsGiftcard, {store_id: user.client.store_ids}
  end

  def sub_client_givex_cards(user)
    cannot :read, Spree::GivexCard
    can :manage, Spree::GivexCard, {client_id: @client_id, store_id: user&.allow_store_ids}
    can :create, Spree::GivexCard
  end

  def sub_client_ts_cards(user)
    can :update_status, Spree::TsGiftcard, {store_id: user&.allow_store_ids}
  end

  def vendor_store_ability
    cannot :read, Spree::Store
    can :manage, Spree::Store, client_id: @client_id
    can :create, Spree::Store
  end

  def fulfilment_team_users_orders(user)
    cannot :read, Spree::Order
    zone_ids =  user.fulfilment_teams.joins(:zones).pluck('spree_zones.id')
    can :manage, Spree::Order, zone_id: zone_ids, shipments: { delivery_mode: ['givex_physical','tsgift_physical'] }
  end

  def fulfilment_team_admin_orders
    cannot :read, Spree::Order
    can :manage, Spree::Order, shipments: { delivery_mode: ['givex_physical','tsgift_physical'] }
  end

  def fulfilment_team_admin_zones
    cannot :read, Spree::Zone
    can :manage, Spree::Zone, fulfilment_zone: true
  end

  def fulfilment_team_admin_users(self_id)
    cannot :read, Spree::User
    can [:index, :update], Spree::User, id: self_id
    can [:index, :update], Spree::User, spree_roles: { name: [:fulfilment_user.to_s] }
    can :manage, Spree::User, spree_roles: { name: [:fulfilment_user.to_s] }
  end

  def fulfilment_user(user)
    cannot :read, Spree::User
    can :manage, Spree::User, id: user.id
  end

  def customer_support_lead
    can [:read, :cancel], [Spree::GivexCard, Spree::TsGiftcard]
  end

  def front_desk_ability
    can :update_status, Spree::TsGiftcard
  end

end
