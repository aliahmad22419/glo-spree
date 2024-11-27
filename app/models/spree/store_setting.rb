module Spree
  class StoreSetting < Spree::Base
    DEFAULT_CONFIG = {}

    belongs_to :store, class_name: 'Spree::Store'

    preference :footer, :json, default: DEFAULT_CONFIG

    end
end
