class SmsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'send_sms'

  def perform(store_id, recipient_phone_number, class_type, slug)
    store = Spree::Store.find_by('spree_stores.id = ?', store_id)
    body = store.preferences[:body]
    if class_type == "Spree::GivexCard"
      card = Spree::GivexCard.find_by(slug: slug)
      param_values = card.generate_givex_data
    else
      card = Spree::TsGiftcard.find_by(slug: slug)
      param_values = card.generate_ts_gift_card
    end
    param_values&.stringify_keys!
    body = body.gsub(/\{\{(.*?)\}\}/) { |match| "#{param_values[$1.strip.tr "{{}}", '']} " }
    SmsWorker.send_sms(body, store&.client&.from_phone_number, recipient_phone_number)
  end

  def self.send_sms(body, from_phone_number, recipient_phone_number)
    client = Aws::SNS::Client.new()

    client.publish(
      topic_arn: ENV['SNS_SEND_SMS'],
      message_attributes: {
        data: {
          data_type: "String",
          string_value: {
            body: body,
            from: from_phone_number,
            to: recipient_phone_number
          }.to_json
        }
      },
      message: "Send SMS"
    )
  end
end
