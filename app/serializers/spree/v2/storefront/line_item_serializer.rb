module Spree
  module V2
    module Storefront
      class LineItemSerializer < BaseSerializer
        set_type :line_item
        belongs_to :variant
        attributes :quantity, :price, :currency,
                   :display_price, :total, :display_total, :adjustment_total,
                   :display_adjustment_total, :additional_tax_total, :vendor_id, :product_id,
                   :vendor_name, :discounted_amount, :display_discounted_amount,
                   :display_additional_tax_total, :promo_total, :display_promo_total, :option_values_text,
                   :included_tax_total, :display_included_tax_total, :message, :variant_id, :delivery_mode, :receipient_first_name,
                   :receipient_last_name, :receipient_email, :receipient_phone_number, :status, :custom_price, :sender_name, :send_gift_card_via

        attribute :order_updated_at do |object|
          object.order.updated_at
        end

        attribute :latest_email_change do |object|
          object.email_changes.includes(:user).latest.as_json(include: {user: {only: [:email]}})
        end

        attribute :email_changes do |object|
          object.email_changes.includes(:user).by_lead.as_json(include: {user: {only: [:email]}})
        end

        attribute :is_giftcard do |object|
          GIFT_CARD_TYPES.include?(object.delivery_mode) && !object&.store&.preferred_single_page
        end

        attribute :variant_sku do |object|
          object.variant&.sku
        end

        attribute :inventory_unit_id do |object|
          object&.inventory_units&.first&.id
        end

        attribute :product do |object, params|
          params.merge!({store: object.store})
          if params[:selected] == 'true'
            sparse_fields = {:product=>[:delivery_mode, :disable_quantity, :default_quantity, :vendor_country, :minimum_order_quantity, :pack_size, :name, :status, :vendor_sku, :sku, :product_type_properties, :slug, :vendor_name, :small_image, :images, :gift_messages, :thumbnail, :vendor_id]}
            Spree::V2::Storefront::ProductSerializer.new(object&.product,  fields:sparse_fields, params: params).serializable_hash if object.variant.present?
          else
            Spree::V2::Storefront::ProductSerializer.new(object&.product, params: params).serializable_hash if object.variant.present?
          end
        end

        attribute :parent_product do |object, params|
          Spree::V2::Storefront::ProductSerializer.new(
            object.product&.parent,  fields: {:product=>[:slug, :daily_stock]},
            params: params.merge!({store: object.store})
          ).serializable_hash if object&.variant&.present? && object&.product&.type_of?("StockProduct")
        end

        attribute :variant_images do |object, params|
          options = {
              params: params
          }
          Spree::V2::Storefront::ImageSerializer.new(object&.variant&.images&.sort_by{|i|[i&.sort_order,i&.id]}&.reverse||[], options).serializable_hash
        end

        attribute :image_urls do |object|
          object&.variant&.image_urls
        end

        attribute :name do |object|
          if object.variant.present? && object.product.present?
            object.name
          else
            "Variant has been deleted"
          end
        end

        attribute :gift_card_iso_number do |object|
          object.line_item_customizations.find_by_name("Serial Number")&.value
        end

        attribute :slug do |object|
          object.slug if object.variant.present? && object.product.present?
        end

        attribute :options_text do |object|
          object.options_text if object.variant.present? && object.product.present?
        end

        attribute :line_item_customizations do |object, params|
          customizations = object.line_item_customizations.joins(:customization)
            .order("spree_customizations.order, spree_customizations.updated_at ASC")
          Spree::V2::Storefront::LineItemCustomizationSerializer.new(customizations, params: params).serializable_hash
        end

        attribute :price_values do |object, params|
          object.price_values(params[:default_currency])
        end

        attribute :refund_notes do |object|
          object&.refund_notes
        end

        attribute :is_master do |object|
          object&.variant&.is_master
        end

        attribute :item_category do |object|
          object&.category&.name if object.variant.present? && object.product.present?
        end

        attribute :blocked_dates do |object|
          object.variant&.product&.blocked_dates&.flatten&.map{ |range| eval(range) }
              &.map{ |r| (Date.parse(r['start_date'])..Date.parse(r['end_date'])).to_a rescue []}
              &.flatten&.map(&:to_s)&.uniq
        end

        attribute :line_item_color_size do |object|
          color_and_size = {color: "", size: "", gender: ""}
          if object.variant.present? && object.product.present?
            variant = object&.variant
            variant&.option_values&.each do |ov|
              if ov.option_type.name.downcase == "colour"
                color_and_size[:color] = ov.name
              end
              if ov.option_type.name.downcase.include?"size"
                color_and_size[:size] = ov.name
              end
            end
            product = object.product
            if color_and_size[:color].blank?
              property_id = product&.properties&.where(name: "Colours")&.last&.id
              colors = ""
              if property_id.present?
                colors = product&.product_properties&.where(property_id: property_id)&.map(&:value)&.join(',')
              end
              color_and_size[:color] = colors
            end

            product = object.product
            categories_name = product&.taxons&.select('name')&.map{|taxon| taxon&.name&.downcase}
            if (categories_name.include?'men') && (categories_name.include?'women')
              color_and_size[:gender] = "unisex"
            elsif categories_name.include?'men'
              color_and_size[:gender] = "male"
            elsif categories_name.include?'women'
              color_and_size[:gender] = "female"
            end
          end
          color_and_size
        end

        attribute :digital_card_details do |object|
          client = object.order.store.client
          data =  if object&.delivery_mode == "givex_digital" || object&.delivery_mode == "givex_physical"
                    object&.givex_cards.select('id, givex_number AS number, card_generated, balance, line_item_id, slug, receipient_phone_number, customer_email, bonus, send_gift_card_via, expiry_date, created_at,iso_code, status').map{|card|
                      {
                          id: card.id,
                          number: card.is_gift_card_number_display(card.number,client),
                          card_generated: card.card_generated,
                          balance: card.balance,
                          line_item_id: card.line_item_id,
                          class_name: card.class.name,
                          slug: card.slug,
                          receipient_phone_number: card&.receipient_phone_number,
                          receipient_email: card&.customer_email,
                          bonus: card.bonus,
                          send_gift_card_via: card.send_gift_card_via,
                          issued_date: card.created_at,
                          expiry_date: card.expiry_date,
                          history_logs: card.history_logs.select('creator_email, history_notes').order(created_at: :desc).first,
                          status: card.status,
                          iso_code: card.iso_code
                      }
                    }
                  elsif object&.delivery_mode == "tsgift_digital" || object&.delivery_mode == "tsgift_physical"
                    object&.ts_giftcards.select('id, number, serial_number, card_generated, balance, line_item_id, slug, receipient_phone_number, customer_email, bonus, send_gift_card_via, expiry_date, created_at, response, status').map{|card|
                      {
                          id: card.id,
                          number: card.is_gift_card_number_display(card.number,client),
                          status: card.status,
                          card_generated: card.card_generated,
                          balance: card.balance,
                          line_item_id: card.line_item_id,
                          class_name: card.class.name,
                          slug: card.slug,
                          receipient_phone_number: card&.receipient_phone_number,
                          receipient_email: card&.customer_email,
                          bonus: card.bonus,
                          send_gift_card_via: card.send_gift_card_via,
                          issued_date: (card.response.present? && JSON.parse(card.response)["value"]["created_at"].present?) ? JSON.parse(card.response)["value"]["created_at"].to_date : '',
                          expiry_date: (card.response.present? && JSON.parse(card.response)["value"]["expiry_date"].present?) ? JSON.parse(card.response)["value"]["expiry_date"].to_date : '',
                          iso_code: card.serial_number,
                          history_logs: card.history_logs.select('creator_email, history_notes').order(created_at: :desc).first

                      }
                    }
                  end
          data
        end

      end
    end
  end
end
