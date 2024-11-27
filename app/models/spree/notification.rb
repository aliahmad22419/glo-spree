module Spree
  class Notification < Spree::Base
    has_many :notifications_vendors, :class_name => 'Spree::NotificationsVendor'
    has_many :vendors, :through => :notifications_vendors
    belongs_to :store, :class_name => 'Spree::Store'
    belongs_to :client, :class_name => 'Spree::Client'

    validates_presence_of :message, :vendors
    validate :validate_vendors

    after_create :send_email_to_vendors

    self.whitelisted_ransackable_attributes = %w[message created_at]

    def send_email_to_vendors
      self.vendors.each do |ven|
        Spree::NotificationMailer.send_email_to_vendors(self, ven.email, ven.name).deliver_now if ven.client_id == client_id
      end
    end

    private

    def validate_vendors
      vendor_ids.map{|vendor_id| errors.add :base, :invalid, message: "You are not authorized to perform this action" unless client.vendor_ids.include?(vendor_id)}
    end

  end
end
