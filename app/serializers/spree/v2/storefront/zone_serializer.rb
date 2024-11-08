module Spree
  module V2
    module Storefront
      class ZoneSerializer < BaseSerializer
        set_type  :zones

        attribute :id, :name, :description, :default_tax, :kind, :zone_members_count, :country_ids, :state_ids,:zone_code

        attribute :country_ids do |object|
          object&.country_ids&.map{|id| id.to_s}
        end

        attribute :state_ids do |object|
          object&.state_ids&.map{|id| id.to_s}
        end

      end
    end
  end
end
