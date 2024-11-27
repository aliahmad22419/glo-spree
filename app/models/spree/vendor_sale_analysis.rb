module Spree
  class VendorSaleAnalysis < Spree::Base
    belongs_to :order, class_name: 'Spree::Order'
    belongs_to :vendor, class_name: 'Spree::Vendor'
    self.whitelisted_ransackable_attributes = %w[completed_at email number]

    def self.completed_at_gt_scope(date)
      where("completed_at >= ?", DateTime.parse(date).beginning_of_day)
    end

    def self.completed_at_lt_scope(date)
      where("completed_at <= ?", DateTime.parse(date).end_of_day)
    end

    def self.ransackable_scopes(auth_object = nil)
      %i(completed_at_gt_scope completed_at_lt_scope)
    end

  end
end
