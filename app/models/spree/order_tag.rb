module Spree
  class OrderTag < Spree::Base
    belongs_to :client, class_name: 'Spree::Client'
    has_and_belongs_to_many :orders, class_name: 'Spree::Order'

    self.whitelisted_ransackable_attributes = %w[label_name]
  end
end
