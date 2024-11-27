module Spree
  class PaymentIntent < Spree::Base
    belongs_to :intentable, polymorphic: true

    enum state: { initiated: 0, canceled: 1 }
    scope :active, -> { initiated.order("created_at").last }
  end
end