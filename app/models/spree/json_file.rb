module Spree
  class JsonFile < ApplicationRecord
    SOURCES = ["FEATURE-VENDORS", "HOME-LISTING", "HOME-BANNER", "FEATURE-BANNER", "CATEGORY-LISTING", "CATEGORIES"]

    before_save :valid_json?, :valid_source?

    has_one_attached :content
    belongs_to :client

    private

      def valid_json?
        is_valid = !!JSON.parse(content.blob.download).all? rescue false

        unless is_valid
          errors.add(:base, "Invalid json format")
          throw(:abort)
        end
      end

      def valid_source?
        unless SOURCES.include?(source.upcase)
          errors.add(:base, "Source denied")
          throw(:abort)
        end
      end
  end
end
