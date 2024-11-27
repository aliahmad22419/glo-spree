module Spree
  module ShippingMethodDecorator
    def self.prepended(base)
      base.has_many :time_slots, class_name: 'Spree::TimeSlot'
      base.has_many :weights, as: :weightable, class_name: "Spree::Weight"
      base.accepts_nested_attributes_for :time_slots, allow_destroy: true, reject_if: :all_blank
      base.accepts_nested_attributes_for :weights, allow_destroy: true, reject_if: :all_blank

      base.after_commit :remove_weights, if: -> { !is_weighted }
      # validate :check_delivery_mode, on: [:create, :update]
      base.whitelisted_ransackable_attributes = %w[
        name admin_name delivery_mode is_weighted
      ]
    end

    def check_delivery_mode
      if delivery_mode.present?
        if client.shipping_methods.where(delivery_mode: delivery_mode).where.not(id:id).exists?
          errors.add(:delivery_mode, 'has already been taken')
        end
      end
    end

    def tax_category
      client.tax_categories.unscoped { super }
    end

    def remove_weights
      weights.destroy_all
    end
  end
end

::Spree::ShippingMethod.prepend(Spree::ShippingMethodDecorator)
