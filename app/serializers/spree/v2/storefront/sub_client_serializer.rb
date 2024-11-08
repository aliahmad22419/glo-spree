module Spree
  module V2
    module Storefront
      class SubClientSerializer < BaseSerializer
        set_type :user

        attributes :email, :name, :allow_store_ids, :is_two_fa_enabled, :is_enabled, :is_v2_flow_enabled, :allow_campaign_ids, :show_full_card_number, :persona_type,
        :service_login_user_id, :can_manage_sub_user

        attribute :allow_store_name do |object|
          Spree::Store&.select('name')&.where(id: object.allow_store_ids)&.map(&:name)&.join(', ')
        end

        attribute :sub_client_menu_item_ids do |object|
          object.sub_client_menu_item_checkboxes(true)
        end

        attribute :role do |object|
          object&.spree_roles[0]&.name
        end
      end
    end
  end
end
