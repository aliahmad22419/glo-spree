module Spree
  class FrontDeskCredential < ApplicationRecord
    belongs_to :user
    validates :tsgifts_email, :tsgifts_password,  presence: true
  end
end
