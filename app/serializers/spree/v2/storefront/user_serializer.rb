module Spree
  module V2
    module Storefront
      class UserSerializer < BaseSerializer
        set_type :user
        set_key_transform :camel_lower # "some_key" => "someKey"
        attributes :email, :name, :current_balance, :news_letter, :spree_api_key, :enabled_marketing, :timezone_list, :lead, :allow_campaign_ids, :user_report_password,
        :can_manage_sub_user

        attribute :addresses do |object, params|
          address_book = object.addresses
          address_book = address_book.where(store_id: params[:store_id]) if params[:store_id].present?
          Spree::V2::Storefront::AddressSerializer.new(address_book).serializable_hash
        end

        attribute :sub_client_menu_item_checkboxes do |object|
          # MenuItems used in sub_client checkboxes
           object.sub_client_menu_item_checkboxes
        end

        attribute :user_menu_items_sidebar do |object|
          # UserMenuItems used in sidebar
          object.sidebar_menu_items
        end

        attribute :menu_item_permissions do |object|
          # MenuItemPermissions used in MenuItemPErmissionGuard for subclient permissions
          object.menu_items.map{|mi| object.menu_item_url(mi)}  if object.user_with_role("sub_client") # only for subclients
        end

        attribute :address_book do |object, params|
          store = Spree::Store.find_by_id params[:store_id] rescue nil
          address_book = object.addresses
          if store.present?
            address_book = address_book.where(store_id: store.id)
            address_book = address_book.where("spree_addresses.country_id IN (?)", store.country_ids)
          end
          Spree::V2::Storefront::AddressSerializer.new(address_book).serializable_hash
        end

        attribute :client do |object|
          (object.try(:client) || object.vendors.last.try(:client)) rescue nil
        end

        attribute :user_client do |object|
          client = (object.try(:client) || object.vendors.last.try(:client)) rescue nil
          Spree::V2::Storefront::ClientSerializer.new(client).serializable_hash
        end

        attribute :logo do |object|
          client = (object.try(:client) || object.vendors.last.try(:client)) rescue nil
          client&.active_storge_url(client&.logo)
        end

        attribute :client_user_api_key do |object, params|
           params.has_key?(:hide_client_user_id) ?
           nil : object&.vendors&.last&.client&.users&.select{|u| u.has_spree_role?('client')}&.first&.spree_api_key
        end

        attribute :currencies do |object|
          if object.user_with_role("client") || object.user_with_role("sub_client") ||
            object.user_with_role("fulfilment_user") || object.user_with_role("fulfilment_super_admin") ||
            object.user_with_role("fulfilment_admin")
            ::Money::Currency.table.uniq {|c| c[1][:iso_code]}.map do |_code, details|
              iso = details[:iso_code]
              [iso, "#{details[:name]} (#{iso})"]
            end
          elsif object.spree_roles.map(&:name).include? "vendor"
            client = (object.try(:client) || object.vendors.last.try(:client)) rescue nil
            client.supported_currencies rescue {}
          else
            {}
          end
        end
        
      end
    end
  end
end
