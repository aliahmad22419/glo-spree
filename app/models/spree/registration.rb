module Spree
  class Registration < Spree::Base
    belongs_to :user, class_name: Spree.user_class.to_s, optional: false
    belongs_to :store, class_name: "Spree::Store", optional: false

    validates_uniqueness_of :user, scope: :store
  end
end
