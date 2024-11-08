class MixpanelWorker
  include Sidekiq::Worker
  require 'socket'
  sidekiq_options queue: 'mixpanel'

  def perform(store,action_name, cookies, remote_ip)
    customer_access_token = cookies.fetch("#{store}_access_token", nil)
    current_customer = Spree::User.find(Spree::OauthAccessToken.by_token(customer_access_token)&.resource_owner_id) if customer_access_token.present?
    guest_customer = cookies.fetch("#{store}_guest_email", nil)
    if current_customer.present?
      mixpanelData = {
        event_name: action_name,
        distinct_id: current_customer.id,
        store_id: store,
        customer_email: current_customer&.email,
        ip: remote_ip,
        type: "logged-in"
      }
    elsif guest_customer.present?
      mixpanelData = {
        event_name: action_name,
        distinct_id: guest_customer,
        store_id: store,
        customer_email: guest_customer,
        ip: remote_ip,
        type: "guest"
      }
    else
      mixpanelData = {
        event_name: action_name,
        distinct_id: remote_ip,
        store_id: store,
        ip: remote_ip,
        type: "non-logged-in"
      }
    end

    client = Aws::SNS::Client.new()
    client.publish(
      topic_arn: ENV['SNS_MIXPANEL_LOGGING'],
      message_attributes: {
        data: {
          data_type: "String",
          string_value: mixpanelData.to_json
        }
      },
      message: "MIXPANEL LOGS"
    )

  end
end
