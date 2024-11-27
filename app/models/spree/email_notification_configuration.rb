module Spree
  class EmailNotificationConfiguration < Spree::Base
    DEFAULT_CONFIG = {}

    belongs_to :store, class_name: 'Spree::Store'

    preference :confirmation, :json, default: DEFAULT_CONFIG
    preference :vendor_confirmation, :json, default: DEFAULT_CONFIG
    preference :shipping, :json, default: DEFAULT_CONFIG

    before_save -> { throw(:abort) } # discontinued, so cannot be changed or created

    def get_preference(preferred_type)
      case preferred_type
      when "confirm"
        return preferred_confirmation
      when "vendor"
        return preferred_vendor_confirmation
      when "shipping"
        return preferred_shipping
      else
        return {}
      end
    end
  end
end
