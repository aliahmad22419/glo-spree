module Spree
  module V2
    module Storefront
      class NotificationSerializer < BaseSerializer
        set_type :notification

        attributes :message, :created_at

        attributes :read do |object, params|
            object&.notifications_vendors.find_by(vendor_id: params[:vendor_id])&.read
        end
      end
    end
  end
end
