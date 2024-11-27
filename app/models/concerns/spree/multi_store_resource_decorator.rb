module Spree
  module MultiStoreResourceDecorator
    def self.included(base)
      base.extend ActiveSupport::Concern
    end

    def must_have_one_store
      # Make nullify must_have_one_store validatioion
    end
  end
end

::Spree::MultiStoreResource.prepend(Spree::MultiStoreResourceDecorator)
