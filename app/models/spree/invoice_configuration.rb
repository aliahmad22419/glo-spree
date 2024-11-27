module Spree
  class InvoiceConfiguration < Spree::Base
    belongs_to :store
    has_one_attached :image, dependent: :destroy
  end
end
