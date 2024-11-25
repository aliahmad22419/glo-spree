
module Spree
  module Api
    module V2
      module Storefront
        module CheckoutControllerDecorator
          def self.prepended(base)
            base.include Spree::PaymentTokenConcern
            base.include Spree::EghlConcern
            base.include Spree::CryptoConcern
            base.include MixPanel
            base.include Spree::EnsureLineItemVendorConcern
            base.before_action :raise_if_product_vendor_changed, except: [:refresh_cart,:set_associate_user,:set_order_email]
            base.rescue_from Spree::Core::GatewayError, with: :rescue_from_spree_gateway_error
            base.before_action :set_order_email, if: Proc.new{ spree_current_order&.email.blank? }
            base.before_action :require_spree_current_user, except: [:payment_methods, :braintree_client, :response_eghl, :response_eghl_call_back, :redirect_front_end], if: Proc.new{ spree_current_order&.email.blank? }
            base.before_action :set_associate_user, only: [:update]
            base.before_action :ensure_synced_cross_browser_cart, only: [:update_billing_address, :update]
            base.before_action :load_gift_card, only: [:update], :if => Proc.new{ params[:apply_giftcard] }
            base.before_action :set_country_by_iso, only: [:update_billing_address]
          end

          def is_synched_cart
            render json: cart_synced_json, status: 200
          end

          def ensure_product_in_stock
            out_of_stock_line_items = spree_current_order.line_items.reject{ |line_item| line_item.stock_status }
            active_product = spree_current_order.line_items.all?{ |item| item.product.status == 'active' }
            if out_of_stock_line_items.present?
              render_error_payload(Spree.t(:insufficient_stock_present, product_name: out_of_stock_line_items.map(&:name).join(', ')), 422)
            elsif !active_product
              render_error_payload(Spree.t(:unable_to_checkout_pending_product), 422)
            else
              render json: {}.to_json, status: 200
            end
          end

          def shipping_rates
            next_service.call(order: spree_current_order)
            result = shipping_rates_service.call(order: spree_current_order)
            shipments_with_rates = spree_current_order.shipments.includes(shipping_rates: :shipment)
            order_line_items = spree_current_order.line_items

            group_by_vendor_and_product_type = {}
            for shipment in shipments_with_rates do
              line_item = shipment&.line_items&.last
              vendor_shipment_type = []
              if DIGITAL_TYPES.include?(line_item.delivery_mode)
                vendor_shipment_type = [line_item.vendor_name, line_item.delivery_mode, line_item.id.to_s]
              elsif FOOD_TYPES.include?(line_item.delivery_mode)
                vendor_shipment_type = [line_item.vendor_name, line_item.delivery_mode, line_item.shipping_category, line_item.product&.effective_date.to_s]
              else
                vendor_shipment_type = [line_item.vendor_name, line_item.delivery_mode]
              end
              rates = shipment.shipping_rates
              ship_obj = {
                id: shipment.id,
                vendor_id: shipment.vendor_id,
                delivery_pickup_date: shipment.delivery_pickup_date
              }
              ship_rates = []
              rates.each do |rate|
                line_item = order_line_items.find(rate.shipment.line_item_id)
                ex_rate = line_item&.exchange_rate(@currency)
                shipping_method = rate.shipping_method
                ship_rates << {
                  id: rate.id,
                  selected: rate.selected,
                  name: shipping_method.name,
                  hide_shipping_method: shipping_method.hide_shipping_method,
                  rate: line_item.tp(rate&.cost * ex_rate, @currency),
                  mode: shipping_method.delivery_mode,
                  thershold: shipping_method.delivery_threshold,
                  cuttofftime: shipping_method.cutt_off_time,
                  timeslots: shipping_method&.time_slots&.map{|interval| {start_time: interval&.start_time, status: nil, slot: interval&.start_time + " - " + interval&.end_time}},
                  scheduled_fulfilled: shipping_method.scheduled_fulfilled,
                  schedule_days_threshold: shipping_method.schedule_days_threshold
                }
              end
              ship_obj[:shipping_rates] =  ship_rates.sort_by {|s| s[:rate].to_f}
              group_by_vendor_and_product_type[vendor_shipment_type] = ship_obj
            end

            render json: { shipments: group_by_vendor_and_product_type, updated_at: spree_current_order.updated_at }, status: 200
          end

          def show
            spree_authorize! :show, spree_current_order, order_token
            render_serialized_payload { serialized_current_order }
          end

          def refresh_cart
            if params[:updated_at].present?
              params[:order] = {};
              params[:order][:updated_at] = params[:updated_at]
            end
            cart_message = cart_synced_json
            render_error_payload(cart_message[:message], cart_message[:status_code]) and return unless cart_message[:synched_cart]
          end

          def update_billing_address
            return if spree_current_store.checkout_v3? && !spree_current_store.enable_v3_billing?
            spree_authorize! :update, spree_current_order, order_token
            attribures = update_billing_address_params
            result = spree_current_order.update(attribures)
            render json: { bill_address_attributes: spree_current_order.bill_address, updated_at: spree_current_order.updated_at }, status: 200
          end

          def update
            spree_authorize! :update, spree_current_order, order_token

            spree_current_order.currency = current_currency if spree_current_order.reload.cart?

            result = update_service.call(
              order: spree_current_order,
              params: params,
              permitted_attributes: permitted_checkout_attributes,
              request_env: request.headers.env
            )

            spree_current_order.add_gift_card_payments(@gift_card) if @gift_card.present?

            if is_cod_or_stripe_pm?
              spree_current_order.payments.checkout.each(&:complete!)
              spree_current_order.update state: :confirm
              result = complete_service.call(order: spree_current_order)
              render_order(result) and return
            else
              spree_current_order.send(:cancel_stripe_payment)
            end

            if params[:order] && params[:order][:shipments_attributes].present?
              params[:order][:shipments_attributes].each { |s|
                shipment = spree_current_order.shipments.find_by('spree_shipments.id = ?', s['id'])
                if shipment.present?
                  shipment.shipping_rates.find_by('spree_shipping_rates.id = ?', s['selected_shipping_rate_id']).update(selected: true)
                  ::Spree::TaxRate.adjust(spree_current_order, [shipment.reload])
                end
              }
              # update totals as a result of shipment tax change
              ::Spree::OrderUpdater.new(spree_current_order).update
            end

            unless (spree_current_order.delivery? || spree_current_order.payment?) && params[:order] && params[:order][:shipments_attributes].present?
              if adyen_payment?
                if spree_current_order.paid_partially # payments.gift_cards.any?
                  render_error_payload(Spree.t(:no_payment_found), 404) and return if spree_current_order.unprocessed_payments.empty?
                  spree_current_order.payments.checkout.each(&:process!)
                  spree_current_order.confirm!
                else
                  # spree_current_order.confirm! if spree_current_order.capture_payments!
                  spree_current_order.confirm! if spree_current_order.process_payments!
                end
              end
            end

            # calculate tax based on selected shipping address
            if params[:order] && params[:order][:ship_address_attributes].present?
              ::Spree::TaxRate.adjust(spree_current_order, spree_current_order.line_items)
            end

            if spree_current_order.shipments.select(&:selected_shipping_rate).count.eql?(spree_current_order.shipments.count)
              spree_current_order.apply_free_shipping_promotions
            end

            if spree_current_order.errors.any?
              render_error_payload(failure(spree_current_order).error)
            else
              render_order(result)
            end
          end

          def rescue_from_spree_gateway_error(exception)
            errors = Spree.t(:spree_gateway_error_flash_for_checkout) + "\n#{exception.message}"
            render_error_payload(errors, 400)
          end

          private

          def is_cod_or_stripe_pm?
            (Spree::Payment.class_eval{ STRIPE_PAYMENT_METHODS }.include?(params[:order][:stripe_payment_method]) &&
              params[:order][:stripe_payment_method].present?) || spree_current_order.cash_on_delivery?
          end

          def set_country_by_iso
            @country = Spree::Country.find_by(iso: params[:order][:bill_address_attributes][:country_iso])
          end

          def update_billing_address_params
            params[:order][:bill_address_attributes].merge!({country_id: @country.id}).delete(:country_iso)
            params[:order].permit(permitted_checkout_attributes)
          end

          def set_associate_user
            if authorized_checkout_user?
              spree_current_order.associate_user!(spree_current_user) if spree_current_order.user.blank?
            elsif doorkeeper_token.present?
              render_error_payload("You are not authorized to this cart", 403)
            elsif spree_current_order.email.blank?
              render_error_payload("Please enter email address", 403)
            end
          end

          def authorized_checkout_user?
            doorkeeper_token.resource_owner_id == spree_current_order.user_id rescue false
          end

          def set_order_email
            guest_email = params[:order][:email] rescue nil
            return if guest_email.blank?

            spree_current_order.email = guest_email
            spree_current_order.save if cart_synced_cross_browser?

            params[:order][:updated_at] = spree_current_order.updated_at.iso8601(3)
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

          def serialize_payment_methods(payment_methods)
            serializer_params = { currency: current_currency, store: spree_current_store, user: spree_current_user }
            payment_methods_serializer.new(payment_methods, params: serializer_params).serializable_hash
          end

          def load_gift_card
            @gift_card = spree_current_store.client.gift_cards.find_by(code: params[:giftcard_code]) if gift_card_payment_method.present?
            if @gift_card.blank?
              render_error_payload(failure(spree_current_order, Spree.t(:gift_code_not_found)).error)
            elsif @gift_card.amount_remaining.zero? || spree_current_order.payments.gift_cards.checkout.any?{|p| p.source_id == @gift_card.id}
              render_error_payload(failure(spree_current_order, "Gift card is already used.").error)
            # elsif @gift_card.amount_remaining.to_f < spree_current_order.price_values[:prices][:payable_amount].to_f
            #   render_error_payload(failure(spree_current_order, "Gift card amount is less than order's amount").error)
            elsif @gift_card.currency != spree_current_order.currency
              render_error_payload(failure(spree_current_order, "Gift card currency not matched").error)
            elsif @gift_card.email != spree_current_order.email
              render_error_payload(failure(spree_current_order, "Gift card not found").error)
            end
            params[:order].delete(:payments_attributes) if params[:order].present?
            params[:checkout][:order].delete(:payments_attributes) if params[:checkout].present? && params[:checkout][:order].present?
          end

          def gift_card_payment_method
            @gift_card_payment_method ||= spree_current_store.client.payment_methods.gift_card.available.first
          end
        end
      end
    end
  end
end

::Spree::Api::V2::Storefront::CheckoutController.prepend(Spree::Api::V2::Storefront::CheckoutControllerDecorator)
