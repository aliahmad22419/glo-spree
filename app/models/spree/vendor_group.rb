module Spree
  class VendorGroup < Spree::Base
    acts_as_paranoid    

    has_many :linked_inventories
    has_many :vendors
    has_many :products, -> { where linked: true } , through: :vendors
    accepts_nested_attributes_for :linked_inventories

  end
end