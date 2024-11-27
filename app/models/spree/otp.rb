module Spree
  class Otp < Spree::Base # ApplicationRecord
    LENGTH = 6
    INTERVAL = 120
    has_one_time_password column_name: :secret_key, length: LENGTH
    belongs_to :user, class_name: 'Spree::User'

    scope :useable, -> { where(verified: false) }

    def verify(code)
      self.authenticate_otp(code, drift: INTERVAL)
    end
  end
end
