module Spree
  class PasswordMailer < ApplicationMailer
    def send_reset_password_emil store, user_email, is_vendor, token, is_customer_support, is_fulfilment_user=nil
      @token = token
      @email = user_email
      @is_vendor = is_vendor
      @store = store
      @is_customer_support = is_customer_support
      @fulfilment_user = is_fulfilment_user
      mail(to: user_email, subject: "Reset Password instructions", from: "techsupport@techsembly.com")
    end

    # Not In use
    # def invite_vendor name_or_email, to, from, store_name
    #   @store_name = store_name
    #   @name = name_or_email
    #   @link = ENV['VENDOR_MANAGEMENT_URL'] + "/vendor-onboarding?email=#{to}"
    #   mail(to: to, from: from, subject: "You have a new message")
    # end

  end
end
