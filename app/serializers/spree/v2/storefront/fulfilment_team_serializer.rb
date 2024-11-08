module Spree
  module V2
    module Storefront
      class FulfilmentTeamSerializer < BaseSerializer
        set_type :fulfilment_team

        attributes :name, :code, :zone_ids, :user_ids
        

        attribute :zone_names do |object|
          object.zones.map(&:name)
        end
      end
    end
  end
end
