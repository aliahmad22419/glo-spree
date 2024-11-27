class Spree::CryptoWallet < Spree::Base
  has_one :payment, as: :source
  belongs_to :payment_method
  belongs_to :user, class_name: "Spree::User", foreign_key: 'user_id', optional: true
end