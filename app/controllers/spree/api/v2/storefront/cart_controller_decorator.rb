module Spree
  module Api
    module V2
      module Storefront
        module CartControllerDecorator
          def self.prepended(base)
            base.include Spree::SpoConcern
            base.include Spree::IframeConcern
            base.include MixPanel
            base.include CheckoutFlowV3

            base.before_action :ensure_synced_cross_browser_cart, only: [:remove_line_item, :apply_coupon_code, :remove_coupon_code, :set_quantity]
            base.before_action :update_shipments, only: [:show, :add_item, :remove_line_item]
            base.before_action :buy_now_item, only: [:add_item]
            base.before_action :apply_glo_promo, only: [:apply_coupon_code, :remove_coupon_code]
            base.before_action :load_variants, only: [:add_item]
            base.before_action :reset_iframe_order_state, only: [:show], if: Proc.new{ spree_current_store.preferred_store_type == "iframe"}
            base.before_action :set_cart_token, only: [:show], if: Proc.new{ params[:generate_cart_token].present? }
            base.before_action :validate_cart_changed, only: [:remove_line_item, :set_quantity, :add_item], if: Proc.new{ params[:cart_changed] }
            base.after_action  :delete_cache_for_cart, only: [:remove_line_item, :add_item, :set_quantity]
            base.skip_before_action :ensure_order, only: [:create_payment_cart, :get_completed_cart]
            base.skip_before_action :load_variant, only: :add_item
          end

          def create
            spree_authorize! :create, Spree::Order
            order_params = {
              user: spree_current_user,
              store: spree_current_store,
              currency: current_currency
            }

            order   = spree_current_order if spree_current_order.present?
            order ||= create_service.call(order_params).value

            render_serialized_payload(201) { serialize_order(order) }
          end

          def add_item
            spree_authorize! :update, spree_current_order, order_token

            result = {}
            params[:variants].each do |variant_hash|
              variant = @variants.find_by('spree_variants.id = ?', variant_hash[:id])
              spree_authorize! :show, variant
              result = send_add_item_service(variant, variant_hash)
              break unless result.success?
            end

            first_variant = @variants[0]
            variant_sku ||= (if first_variant.product.daily_stock?
              first_variant.product.parent.master.sku
            else first_variant.sku end rescue nil)

            if result.success?
              delivery_modes = spree_current_order.line_items.map(&:delivery_mode)
              all_digital_or_physical = false
              if delivery_modes.all?{|line| DIGITAL_TYPES.include?line}
                all_digital_or_physical = true
              elsif delivery_modes.all?{|line| PHYSICAL_TYPES.include?line }
                all_digital_or_physical = true
              end
              spree_current_order.reload
              render_serialized_payload { success({
                success: true,
                all_digital: all_digital_or_physical,
                line_item_count: delivery_modes.count,
                variant_sku: variant_sku,
                product_quantities: spree_current_order.product_quantities
                }).value
              }
            else
              render_error_payload(result.error)
            end
          end

          def update_shipments
            spree_current_order.reset_order_state if params[:reset_state].blank?
          end

          def buy_now_item
            spree_current_order.line_items.destroy_all if params[:buy_now_button].present? && params[:buy_now_button]
          end

          def apply_glo_promo
            return unless cart_synced_cross_browser?

            spree_current_order.glo_promo = params[:apply]
            spree_current_order.save
            params[:order][:updated_at] = spree_current_order.updated_at.iso8601(3) if params[:order].present?
          end

          def load_variants
            @variants = Spree::Variant.where('spree_variants.id IN (?)', params[:variants]&.pluck(:id))
          end

          private
          # def promotion_handler
          #   Spree::PromotionHandler::Coupon.new(spree_current_order)
          #end

          def send_add_item_service(variant, options)
            add_item_service.call(
              order: spree_current_order,
              variant: variant,
              quantity: options[:quantity],
              options: options[:options]
            )
          end

          def delete_cache_for_cart
            spree_current_order&.store&.clear_store_cache()
          end

          def set_cart_token
            spree_current_order.generate_cart_token
          end

          def serialize_order(order)
            if current_currency
              resource_serializer.new(
                order.reload,
                include: resource_includes,
                fields: sparse_fields,
                params: { default_currency: current_currency, store: order.store }
              ).serializable_hash
            else
              super
            end
          end
        end
      end
    end
  end
end

::Spree::Api::V2::Storefront::CartController.prepend(Spree::Api::V2::Storefront::CartControllerDecorator)
