
module Spree
  class GiftCardPdf < Spree::Base
    DEFAULT_CONFIG = {
      header: 'This gift invites you to take a journey with Us.',
      introduction: 'Quote the unique Gift Card Number.',
      qr_code: 'This QR code is for internal redemption processes.',
      customer_service: '',
      footer: "Copyright © #{Date.today.year}"
    }
    belongs_to :store
    preference :monetary, :json, default: DEFAULT_CONFIG
    preference :experiences, :json, default: DEFAULT_CONFIG
    preference :givex, :json, default: DEFAULT_CONFIG
  end
end
