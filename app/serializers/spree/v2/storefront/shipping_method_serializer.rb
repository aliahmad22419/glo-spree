module Spree
  module V2
    module Storefront
      class ShippingMethodSerializer < BaseSerializer
        set_type :shipping_method

        attributes :name, :display_on, :admin_name, :code, :tracking_url, :visible_to_vendors,
                   :delivery_mode, :delivery_threshold, :time_slots, :store_ids, :cutt_off_time, :lalamove_enabled,
                   :lalamove_service_type, :auto_schedule_lalamove, :hide_shipping_method, :scheduled_fulfilled, :schedule_days_threshold,
                   :is_weighted, :weights

        attribute :calculator do |object|
          object.calculator.description
        end

        attribute :param_name do |object|
          object.name.parameterize
        end

        attribute :vendor_name do |object|
          object&.vendor&.name
        end
        
        attribute :preferences do |object|
          object.calculator.preferences
        end

        attribute :calculator_type do |object|
          object.calculator.type
        end

        attribute :zones do |object|
          object.zones.collect(&:name).join(", ")
        end

        attribute :zone_ids do |object|
          object.zone_ids.map{|id| id.to_s}
        end

        attribute :shipping_category_ids do |object|
          object.shipping_category_ids.map{|id| id.to_s}
        end

        attribute :tax_category_id do |object|
          object.tax_category_id.to_s
        end
        
      end
    end
  end
end
