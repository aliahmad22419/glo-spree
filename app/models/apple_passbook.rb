class ApplePassbook < ApplicationRecord
  include Spree::Preferences::Preferable
  serialize :preferences, Hash

  preference :enable, :boolean, default: false
  belongs_to :store, class_name: "Spree::Store"
  before_save :validate_json
  # Remove certificate attached to store
  before_destroy -> { self.store.passbook_certificate.purge_later }

  def validate_json
    return unless pass.present?   
    begin
      JSON.parse(pass)
      return true
    rescue Exception => e
      errors.add(:base, "Invalid Json: " + e.message)
      throw(:abort)
    end
  end
end
