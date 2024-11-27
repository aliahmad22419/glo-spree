
module Spree
  module UserDecorator
    # def self.included(base)
    #   include UserEmailValidations
    # end

    def self.prepended(base)

      base.include UserEmailValidations

      base.validate :password_requirements_are_met
      base.whitelisted_ransackable_attributes = %w[email name]

      base.attr_accessor :subscription_status

      base.after_create :create_wishlist , if: Proc.new { spree_roles.where(name: 'customer').present? }#, :enable_two_fa
      base.after_create :add_default_sub_client_routes, if: Proc.new { self.spree_roles.where(name: 'sub_client').present? }
      base.after_destroy :attach_id_to_email
      base.after_update :clear_access_tokens, if: Proc.new { saved_change_to_is_enabled? && !is_enabled}
      base.before_save :reset_non_fd_setting

      base.has_many :menu_item_users, dependent: :destroy
      base.has_many :menu_items, through: :menu_item_users, class_name: '::MenuItem'
      base.accepts_nested_attributes_for :menu_item_users, allow_destroy: true

      base.has_many :otps, dependent: :destroy, class_name: 'Spree::Otp'

      base.scope :with_role, -> (role){ joins(:spree_roles).where("spree_roles.name = ?", role).last }
      base.scope :without_role, -> (role, email) { joins(:spree_roles).where("spree_roles.name != ? AND lower(spree_users.email) = ?", role, email.downcase) }
      base.has_one :subscription, dependent: :destroy, class_name: "Spree::Subscription"
      base.belongs_to :store, class_name: 'Spree::Store'

      base.has_many :followed_users, foreign_key: :follower_id, class_name: 'Spree::Follow'
      base.has_many :followees, through: :followed_users
      base.has_many :following_users, foreign_key: :followee_id, class_name: 'Spree::Follow'
      base.has_many :followers, through: :following_users
      base.has_one :front_desk_credential, class_name: 'Spree::FrontDeskCredential'
      base.has_many :bulk_orders, class_name: 'Spree::BulkOrder'
      base.has_and_belongs_to_many :fulfilment_teams, class_name: 'Spree::FulfilmentTeam'
    end

    #
    FULFILMENT_ROLES = [:fulfilment_super_admin.to_s, :fulfilment_admin.to_s, :fulfilment_user.to_s].freeze unless const_defined?(:FULFILMENT_ROLES)
    USER_MENU_ITEM_NAMESPACES = { sub_client: 'vendor-management', client: 'vendor-management', vendor: 'vendor' } unless const_defined?(:USER_MENU_ITEM_NAMESPACES)
    SINGLE_VENDOR_MENUS = { "Vendors" => "/vendors"} unless const_defined?(:SINGLE_VENDOR_MENUS)

      def password_requirements_are_met
        return if password.blank?
        rules = {
            "must contain at least one special character" => /[^A-Za-z0-9]+/
        }

        rules.each do |message, regex|
          errors.add( :password, message ) unless password.match( regex )
        end
      end

      def firstname
        self&.bill_address&.firstname || ""
      end

      def lastname
        self&.bill_address&.lastname || ""
      end

      def create_wishlist
        wishlists.create(name: Spree.t(:default_wishlist_name), store_id: store_id, is_default: true)
      end

      def add_default_sub_client_routes
        default_routes = [
          [ "Dashboard", "/sub-client-landing" ],
          [ "Edit Stock User", "/stock-User/:id" ]
        ]

        default_routes.each do |route|
          next if menu_items.where(name: route[0], url: route[1]).present?

          menu_item = ::MenuItem.find_by(name: route[0], url: route[1])
          menu_item_users.create(menu_item_id: menu_item.id, visible: menu_item.visible, permissible: menu_item.permissible)
        end
      end

      def enable_two_fa
        if self.spree_roles.first.name == 'client' or self.spree_roles.first.name == 'vendor'
          self.is_two_fa_enabled = true
        end
      end

      def current_balance
        store_credits.reload.order(id: :asc).last&.balance.to_f
      end

      def incomplete_order(store)
        orders.incomplete.order(:created_at).find_by(store: store)
      end

      def active_otp
        self.otps.useable.last
      end

      def generate_otp
        otp = active_otp
        otp_code_was = otp.otp_code(otp.created_at) rescue nil # no record created yet
        otp = self.otps.create if otp.blank? || !(otp&.verify(otp_code_was))
        otp.otp_code(otp.created_at)
      end

      def user_with_role(role)
        spree_roles.map(&:name).include?role
      end

      def menu_item_url(menu_item)
        return menu_item.url unless menu_item.namespace?
        "/#{USER_MENU_ITEM_NAMESPACES[spree_roles.first.name.to_sym]}#{menu_item.url}"
      end

      def sidebar_menu_items
        if user_with_role("sub_client")
          items = self.menu_item_users.visible.parent_menus.map do |item|
            hash = { children: [] }
            hash.merge!(item.menu_item.menu_item_hash(self))
            item.sub_menu_item_users.visible.each do |smi|
              hash[:children].push(smi.menu_item.menu_item_hash(self))
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

      def sub_client_menu_item_checkboxes
        items = ::MenuItem.permissible.parent_menus.items_with_role(['sub_client'])
        items = items.where("id NOT IN (?)", self.single_vendor_menu_ids) if user_with_role("client") && !self.client.multi_vendor_store
          items = items.map do |item|
            hash = { children: [] }
            hash.merge!(item.menu_item_hash(self))
            hash[:children] = item.sub_menu_items.permissible.items_with_role(['sub_client']).map{|smi| smi.menu_item_hash(self)}.sort_by{ |obj| obj[:priority] }
            hash.delete(:children) if hash[:children].blank?
            hash
          end
        items = items.sort_by{ |obj| obj[:priority] }
      end

      def single_vendor_menu_ids
        ::MenuItem.where("name IN (?) AND url IN (?)", SINGLE_VENDOR_MENUS.keys, SINGLE_VENDOR_MENUS.values).ids
      end

      def has_access_to_home?
        return true if user_with_role("client")
        user_with_role("sub_client") && menu_item_users.joins(:menu_item).where("menu_items.name = ? AND menu_items.url = ?", 'Home', '/reporting').present?
      end

      def clear_access_tokens
        Spree::OauthAccessToken.where(resource_owner_id: id).destroy_all
      end

      def validate_user(headers, role)
        expected_headers =  ["Name", "Email", "Password", "Role", "V2 flow", "Enable 2FA", "Enable Access"]
        return "Invalid CSV file." if headers != expected_headers
        return "User name can't be blank" if !name.present?
        email_pattern = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
        return "Invalid email format" unless email.match?(email_pattern)
        return "Role should be Redemption" if role != "Redemption"
        return nil
      end

      private

      def reset_non_fd_setting
        return if is_v2_flow_enabled? && has_spree_role?(:front_desk)

        self.show_full_card_number = false
      end

      def attach_id_to_email
        Spree::User.unscoped.find_by_email(email_was)&.update(email: email_was.gsub(/@/, id.to_s+'\0'))
      end

  end
end

::Spree::User.prepend(Spree::UserDecorator) unless ::Spree::User.ancestors.include?(Spree::UserDecorator)
