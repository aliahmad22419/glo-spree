# Spree::Stores::FindCurrent.class_eval do
# end

module Spree
  module Stores
    module FindCurrentDecorator

    end
  end
end

::Spree::Stores::FindCurrent.prepend(Spree::Stores::FindCurrentDecorator)
