module Spree
  class Persona < Spree::Base
    belongs_to :client
    enum persona_code: { default: 0, admin: 1, editor: 2, fulfilment: 3 }
  end
end
