module Spree
  module V2
    module Storefront
      class FollowSerializer < BaseSerializer
        set_type :follow

        attributes :follower_id, :followee_id, :name, :email, :details, :status, :website, :instagram, :country_name,
                   :created_at, :updated_at

        attribute :vendor_id do |object|
          object&.follower&.vendors&.first&.id
        end

      end
    end
  end
end
