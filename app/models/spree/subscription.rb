module Spree
  class Subscription < Spree::Base
    STATES = [:subscribed, :unsubscribed]
    belongs_to :store, class_name: 'Spree::Store'
    belongs_to :user, class_name: 'Spree::User'

    def add_to_list action
      Gibbon::Request.api_key = self.store.mailchimp_setting&.mailchimp_api_key
      result = begin
        result = send(action)
        result = (result ? result.body : {})
        update(subscriber_id: result[:id], status: result[:status]) if result[:id].present?
        { status: 200, message: "#{result[:email_address]} #{result[:status]} successfully" }
      rescue Gibbon::MailChimpError => e
        puts e.inspect
        { status: e.status_code, message: e.title }
      end

      return result
    end

    def add_list_member
      first_name = user.try(:firstname) || "unknown firstname"
      last_name = user.try(:lastname) || "unknown lastname"

      Gibbon::Request.lists(self.store.mailchimp_setting&.mailchimp_list_id).members
        .create(
          params: { skip_merge_validation: true },
          body: {
          email_address: self.email,
          status: STATES[0],
          merge_fields: { FNAME: first_name, LNAME: last_name }
        })
    end

    def subscribe
      return self.add_list_member unless self.user_id.present?

      Gibbon::Request.lists(self.store.mailchimp_setting&.mailchimp_list_id)
        .members(Digest::MD5.hexdigest(user.email.downcase))
        .update(body: { email_address: self.email, status: STATES[0] }, params: { skip_merge_validation: true })
    end

    def unsubscribe
      Gibbon::Request.lists(self.store.mailchimp_setting&.mailchimp_list_id)
        .members(Digest::MD5.hexdigest(user.email.downcase))
        .update(body: { status: STATES[1] })
    end
  end
end
