module Spree
  module Api
    module V2
      class BaseSerializer
        include JSONAPI::Serializer
        # Override It to avoid caching
      end
    end
  end
end
