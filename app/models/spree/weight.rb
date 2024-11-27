module Spree
  class Weight < Spree::Base
    belongs_to :weightable, polymorphic: true, optional: true

    validate :max_greater_than_min?
    private

    def max_greater_than_min?
      errors.add(:maximum, "must be greater than minimum") and throw(:abort) unless maximum > minimum
    end
  end
end
