module Spree
  class Redirect < Spree::Base
    belongs_to :store
    validates :from, uniqueness: { scope: :store_id, message: "should be unique per route." }

    self.whitelisted_ransackable_attributes = %w[from to]
  end
end
