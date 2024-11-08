module Spree
  class NotificationMailer < BaseMailer

    def send_email_to_vendors notification, vendor_email, name
      @name = name
      @message = notification.message
      @store = notification.store
      client = notification&.client
      @client_logo = client&.active_storge_url(client&.logo)
      mail(to: vendor_email, from: "#{client&.name} <#{client&.users&.first&.email}>", cc: cc_store_recipients(@store), subject: "You have a new message")
    end

  end
end
