module Spree
  class TwilioTextMessage

    def call(store, recipient_phone_number)
      client = Twilio::REST::Client.new(store.preferences[:account_sid], store.preferences[:auth_token])
      client.messages.create({
                               from: store.preferences[:from_phone_number],
                               to: recipient_phone_number,
                               body: store.preferences[:body]
                             })
    end
  end
end
