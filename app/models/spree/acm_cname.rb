module Spree
  class AcmCname < Spree::Base
    belongs_to :store, :class_name => 'Spree::Store'
  end
end
