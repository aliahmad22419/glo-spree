module Spree
  class NotificationsVendor < Spree::Base

    belongs_to :vendor, :class_name => 'Spree::Vendor'
    belongs_to :notification, :class_name => 'Spree::Notification'

  end
end
