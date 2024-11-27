module Spree
  module Metadata
    extend ActiveSupport::Concern
    # Error serialize: wrong number of arguments (given 2, expected 1) (ArgumentError)
    # included do
    #   attribute :public_metadata, default: {}
    #   attribute :private_metadata, default: {}
    #   serialize :public_metadata, HashSerializer
    #   serialize :private_metadata, HashSerializer
    # end
    included do
      store :public_metadata, coder: HashSerializer
      store :private_metadata, coder: HashSerializer
    end

    # https://nandovieira.com/using-postgresql-and-jsonb-with-ruby-on-rails
    class HashSerializer
      def self.dump(hash)
        hash
      end

      def self.load(hash)
        if hash.is_a?(Hash)
          hash.with_indifferent_access
        else
          {}
        end
      end
    end
  end
end
