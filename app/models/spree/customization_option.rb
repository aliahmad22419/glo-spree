module Spree
  class CustomizationOption < Spree::Base
    belongs_to :customization, :class_name => 'Spree::Customization'

  end
end
