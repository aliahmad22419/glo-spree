module Spree
  class Customization < Spree::Base
    has_many :customization_options, dependent: :destroy, :class_name => 'Spree::CustomizationOption'
    belongs_to :product, :class_name => 'Spree::Product'

    accepts_nested_attributes_for :customization_options, allow_destroy: true


  end
end
