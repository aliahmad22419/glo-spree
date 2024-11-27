module Spree
  class Page < Spree::Base
    self.default_ransackable_attributes = %w[title status updated_at created_at static_page]
    validates_presence_of :title, :content
    validates :store_ids, presence: { if: -> { static_page } }

    has_and_belongs_to_many :stores, class_name: 'Spree::Store'

    scope :static, -> { where(static_page: true) }

    def self.create_at_gt_scope(date)
      where("created_at > ?", DateTime.parse(date).beginning_of_day)
    end

    def self.create_at_lt_scope(date)
      where("created_at < ?", DateTime.parse(date).end_of_day)
    end

    def self.ransackable_scopes(auth_object = nil)
      %i(create_at_gt_scope create_at_lt_scope)
    end

  end
end
