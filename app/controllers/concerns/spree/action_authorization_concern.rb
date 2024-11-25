module Spree
  module ActionAuthorizationConcern

    def check_permissions
      return if spree_current_user.blank? || params[:action].to_s.eql?('get_user_roles')

      role_name = spree_current_user.spree_roles[0].name.to_sym
      access_json = I18n.t(role_name)
      controller_name = params['controller'].split('/').last&.to_sym
      controller_actions = access_json[controller_name]
      other_disallowed_action = access_json[:other_disallowed_action]
      
      render_unauthorized_access and return if controller_actions.blank? && other_disallowed_action.present?
      return unless controller_actions.present?

      action = params[:action].to_sym
      allowed_actions = controller_actions[:allow]
      disallowed_actions = controller_actions[:disallow]
      render_unauthorized_access and return if disallowed_actions.include?('*') || disallowed_actions.include?(action.to_s)
      
      return unless allowed_actions.length > 0
      render_unauthorized_access and return unless allowed_actions.include?('*') || allowed_actions.include?(action.to_s)
    end

    def sub_client_authorization
      return unless spree_current_user.present? && spree_current_user.has_spree_role?(:sub_client)
      
      controller_name = params['controller'].split('/').last&.to_sym
      action_name = params['action']&.to_sym
      menu_item = ::MenuItem.find_by(controller: controller_name&.to_s)
      return unless menu_item

      if menu_item.actions.any?
        if menu_item.actions.include?(action_name&.to_s)
          render_unauthorized_access unless menu_item.user_ids.include?(spree_current_user.id)
        else
          sub_menu_items(menu_item, action_name&.to_s)
        end
      else
        sub_menu_items(menu_item, action_name&.to_s)
      end
    end

    def sub_menu_items(menu_item, action_name)
      sub_menu = menu_item.sub_menu_items.where('actions @> ARRAY[?]::text[]', [action_name])[0]

      if sub_menu.present?
        render_unauthorized_access unless sub_menu.user_ids.include?(spree_current_user.id)
      end
    end

    def unauthorized_frontdesk_user
      return unless spree_current_user.present?

      render_unauthorized_access if spree_current_user.has_spree_role?(:front_desk)
    end

    def unauthorized_fulfilment_user
      return unless spree_current_user.present?

      render_unauthorized_access if spree_current_user.has_spree_role?(:fulfilment_user)
    end

    def unauthorized_fulfilment_super_admin
      return unless spree_current_user.present?

      render_unauthorized_access if spree_current_user.has_spree_role?(:fulfilment_super_admin)
    end

    def unauthorized_fulfilment_admin
      return unless spree_current_user.present?

      render_unauthorized_access if spree_current_user.has_spree_role?(:fulfilment_admin)
    end

    def unauthorized_user_with_fulfilment_role
      return if params[:controller] == "countries"
      return unless spree_current_user.present?

      render_unauthorized_access if (spree_current_user.has_spree_role?(:fulfilment_admin) || spree_current_user.has_spree_role?(:fulfilment_super_admin) || spree_current_user.has_spree_role?(:fulfilment_user))
    end

    # def unauthorized_customer
    #   return unless spree_current_user.present?

    #   render_unauthorized_access if spree_current_user.has_spree_role?(:customer)
    # end

    def unauthorized_customer_support
      return if params[:controller] == "countries"
      return unless spree_current_user.present?

      render_unauthorized_access if spree_current_user.has_spree_role?(:customer_support)
    end

    def authorized_cs_lead
      render_unauthorized_access unless spree_current_user.has_spree_role?(:customer_support) && spree_current_user.lead?
    end

    def unauthorized_vendor
      return if params[:controller] == "countries"
      return unless spree_current_user.present?

      render_unauthorized_access if spree_current_user.has_spree_role?(:vender)
    end

    def authorized_client_sub_client
      return unless spree_current_user.present?

      render_unauthorized_access unless spree_current_user.has_spree_role?(:client) || spree_current_user.has_spree_role?(:sub_client)
    end

    def authorized_client_sub_client_vendor
      render_unauthorized_access unless spree_current_user.has_spree_role?(:client) || spree_current_user.has_spree_role?(:sub_client) || spree_current_user.has_spree_role?(:vendor)
    end

    def unauthorized_roles_except_fulfilment
      return unless spree_current_user.present?

      render_unauthorized_access unless (spree_current_user.has_spree_role?(:fulfilment_admin) || spree_current_user.has_spree_role?(:fulfilment_super_admin) || spree_current_user.has_spree_role?(:fulfilment_user))
    end

    def render_unauthorized_access
      return render json: { error: "You are not authorized to perform this action" }, status: 403
    end

    def fulfilment_role_permissions
      (spree_current_user.has_spree_role?(:fulfilment_admin) || spree_current_user.has_spree_role?(:fulfilment_super_admin))
    end
  end
end
