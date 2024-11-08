module Spree
  module V2
    module Storefront
      class PersonaSerializer < BaseSerializer
        set_type :persona
        attributes :id, :name, :persona_code, :store_ids, :menu_item_ids, :campaign_ids
      end
    end
  end
end