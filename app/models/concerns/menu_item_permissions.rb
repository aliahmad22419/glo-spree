module MenuItemPermissions
  extend ActiveSupport::Concern
  DEFAULT_PERMISSIONS = [ '/sub-client-landing', '/stock-product/:id' ]
  USER_MENU_ITEM_NAMESPACES = { sub_client: 'vendor-management', client: 'vendor-management', vendor: 'vendor' }
  SINGLE_VENDOR_MENUS = { "Vendors" => "/vendors"}
  
  included do
    after_create :add_default_sub_client_routes, if: Proc.new { self.spree_roles.where(name: 'sub_client').present? }
  end

  def sidebar_menu_items
    if user_with_role("sub_client")
      items = self.menu_item_users.visible.parent_menus.map do |item|
        hash = { children: [] }
        hash.merge!(item.menu_item.menu_item_hash(self))
        item.sub_menu_item_users.visible.each do |smi|
          hash[:children].push(smi.menu_item.menu_item_hash(self))
          hash[:children] = hash[:children]&.sort_by { |child| child[:priority] }
        end
        hash.delete(:children) if hash[:children].blank?
        hash
      end
    else
      # NOTE as for now we don't save the menu item users for client role so need to get all menu item
      # otherwise it should collect data from menu item users as above in if condition
      items = ::MenuItem.visible.parent_menus.items_with_role([spree_roles.first.name])

      # Exclude Linked inventory if vendory id not part of any vendor group
      linked_inventory_id = ::MenuItem.find_by(name: "Linked Inventory", url: "#")&.id
      items = items.where.not(id: linked_inventory_id) if user_with_role("vendor") && self.vendors.last.vendor_group.blank?

      items = items.where("id NOT IN (?)", self.single_vendor_menu_ids) if user_with_role("client") && !self.client.multi_vendor_store
      items = items.map do |item|
        hash = {id: item.id, children: []}
        hash.merge!(item.menu_item_hash(self))
        hash[:children] = item.sub_menu_items.visible.map{|smi| smi.menu_item_hash(self)}
        hash[:children] = hash[:children].sort_by{ |obj| obj[:priority] }
        hash.delete(:children) if hash[:children].blank?
        hash
      end
    end
    items = items.sort_by{ |obj| obj[:priority] }
  end

  def build_checkbox(menu, permission_id = nil, user_scope = false)
    {
      id: permission_id,
      menu_item_id: menu.id,
      name: menu.name,
      user_id: (user_scope ? id : nil),
      visible: menu.visible,
      enabled: false,
      selected: permission_id.present?,
      priority: menu.priority,
      _destroy: false,
      children: []
    }
  end

  def sub_client_menu_item_checkboxes(user_scope = false)
    assigned_items = {}
    assigned_items = self.menu_item_users.each_with_object({}){ |item, hash| hash[item.menu_item_id] = item.id } if user_scope
  
    items = ::MenuItem.permissible.parent_menus.where.not(url: Spree::User::DEFAULT_PERMISSIONS).items_with_role(['sub_client'])
    items = items.where("id NOT IN (?)", self.single_vendor_menu_ids) if self.user_with_role("client") && !self.client.multi_vendor_store
    items = items.map do |parent_item|
      hash = self.build_checkbox(parent_item, assigned_items[parent_item.id], user_scope)
      hash[:children] = parent_item.sub_menu_items.permissible.items_with_role(['sub_client']).map{ |child_item|
          self.build_checkbox(child_item, assigned_items[child_item.id], user_scope)
        }.sort_by{ |obj| obj[:priority] }
      hash
    end
    items.sort_by{ |obj| obj[:priority] }
  end

  def menu_item_url(menu_item)
    return menu_item.url unless menu_item.namespace?
    "/#{USER_MENU_ITEM_NAMESPACES[spree_roles.first.name.to_sym]}#{menu_item.url}"
  end

  def single_vendor_menu_ids
    ::MenuItem.where("name IN (?) AND url IN (?)", SINGLE_VENDOR_MENUS.keys, SINGLE_VENDOR_MENUS.values).ids
  end

  def has_access_to_home?
    return true if user_with_role("client")
    user_with_role("sub_client") && menu_items.find_by(name: 'Home', url: '/reporting').present?
  end

  private
  
  def add_default_sub_client_routes
    DEFAULT_PERMISSIONS.each do |route_url|
      next if menu_items.find_by_url(route_url).present?

      menu_item = ::MenuItem.find_by_url(route_url)
      menu_item_users.create(menu_item_id: menu_item.id, visible: menu_item.visible, permissible: menu_item.permissible)
    end
  end
end
