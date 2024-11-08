module Spree
  module V2
    module Storefront
      class ShipmentSerializer < BaseSerializer
        set_type :shipment

        attributes :id, :state, :tracking, :shipped_at, :vendor_id, :delivery_pickup_time, :delivery_mode, :order_id, :cost,
                   :fulfilment_status, :fulfilment_info_id

        attribute :shipping_method do |object|
          object&.shipping_method&.name
        end

        attribute :internal_name do |object|
          object&.shipping_method&.admin_name.presence || "N/A"
        end

        attribute :lalamove_enabled do |object|
          object&.shipping_method&.lalamove_enabled
        end

        attribute :store_name do |object|
          object&.order&.store&.name
        end

        attribute :lalamove_order_response do |object|
          object&.lalamove_order_response.present? ? JSON.parse(object&.lalamove_order_response) : ''
        end

        attribute :delivery_pickup_date do |object|
          object&.delivery_pickup_date&.strftime("%d %B %Y")
        end

        attribute :number do |object|
          object&.order&.number
        end

        attribute :line_items do |object, params|
          Spree::V2::Storefront::LineItemSerializer.new(object.line_items&.compact, params: params).serializable_hash
        end

        attribute :vendor_details do |object|
          vendor = object&.vendor
          logo_url = Spree::Image.where(id: vendor&.image_id).first
          logo_url = logo_url&.active_storge_url(logo_url&.attachment)
          shipping_from_address = Spree::V2::Storefront::AddressSerializer.new(object&.vendor&.ship_address).serializable_hash
          {id: vendor.id, contact_name: vendor.name || vendor.contact_name, phone: vendor.phone,
           shipping_from_address: shipping_from_address, logo_url: logo_url}
        end

        attribute :lalamove_initail_dateTime do |object|
          scheduled_at = ''
          if object&.delivery_pickup_date
            d = object.delivery_pickup_date
            t = object.delivery_pickup_time.split('-').last
            t = Time.parse(t)
            scheduled_at = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec, t.zone).strftime('%Y-%m-%dT%H:%M')
          end
          scheduled_at
        end

        attribute :card_generation_datetime do |object|
          object.card_generation_datetime.strftime("%x %I:%M:%S %p") if object.card_generation_datetime.present?
        end

        attribute :scheduled_fulfilled do |object|
          object.shipping_method.scheduled_fulfilled
        end

        attribute :shipment_charges do |object|
          exchange_value = (Spree::LineItem.find_by_id(object.line_item_id)&.saved_exchange_rate || 1)
          object.order.tp((object.cost * exchange_value), object.order.currency)
        end

        attribute :schedule_days_threshold do |object|
          object.shipping_method.schedule_days_threshold
        end

        attribute :replacements_limit do |object, params| # returns whether replacement card limit exceeded or not
          if params[:current_user].present? && %w[fulfilment_super_admin fulfilment_admin fulfilment_user].include?(params[:current_user].spree_roles[0].name)
            replacements_count = object.fulfilment_info&.replacements&.count || 0
            replacements_count >= 5 && object.fulfilment_info&.replacements&.last&.replacement_fulfiled?
          end
        end

        attribute :replacements_count do |object, params|
          if params[:current_user].present? && %w[fulfilment_super_admin fulfilment_admin fulfilment_user].include?(params[:current_user].spree_roles[0].name)
            object.fulfilment_info&.replacements&.count
          end
        end
      end
    end
  end
end
