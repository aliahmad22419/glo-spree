module Spree
  module Api
    module V2
      module Storefront
        class LineItemsController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2::Storefront::OrderConcern

          before_action :require_spree_current_user, only: [:best_selling_report, :get_csv, :update_item, :send_gift_cards_email, :send_gift_cards_sms, :update_recipient_email]
          before_action :set_line_item, only: [:show, :update, :request_refund, :update_item, :regenerate_gift_cards, :update_recipient_email]
          before_action :ensure_synced_cross_browser_cart , only: [:bulk_update]
          before_action :ensure_lead, :ensure_term_agreed, only: [:update_recipient_email]
          after_action :delete_cache_for_lineitem, only: [:update]
          before_action :authorized_client_sub_client_vendor, only: [:best_selling_report]
          before_action :check_permissions
          before_action :validate_processable_card, only: [:regenerate_gift_cards]

          def show
            render_serialized_payload { serialize_resource(resource) }
          end

          def update_recipient_email
            if @line_item.update(update_recipient_params)
              render_serialized_payload { serialize_resource(@line_item.reload) }
            else
              render_error_payload(failure(@line_item).error) 
            end
          end

          def update
            @line_item.receipient_email = params[:line_item_attributes][:receipient_email] if params[:line_item_attributes][:receipient_email].present?
            @line_item.receipient_first_name = params[:line_item_attributes][:receipient_first_name] if params[:line_item_attributes][:receipient_first_name].present?
            @line_item.receipient_last_name = params[:line_item_attributes][:receipient_last_name] if params[:line_item_attributes][:receipient_last_name].present?
            @line_item.receipient_phone_number = params[:line_item_attributes][:receipient_phone_number]
            @line_item.delivery_mode = params[:line_item_attributes][:delivery_mode] if params[:line_item_attributes][:delivery_mode].present?
            @line_item.sender_name = params[:line_item_attributes][:sender_name] if params[:line_item_attributes][:sender_name].present?
            @line_item.message = params[:line_item_attributes][:message] if params[:line_item_attributes][:message]
            @line_item.quantity = params[:line_item_attributes][:quantity] if params[:line_item_attributes][:quantity].present?
            @line_item.variant_id = params[:line_item_attributes][:variant_id] if params[:line_item_attributes][:variant_id].present?

            customization_options = params[:line_item_attributes][:customization_options].to_a
            if @line_item.is_edit_mode = params[:line_item_attributes][:edit_product]
              custom_amount_opt = customization_options.find{ |opt| opt[:gift].present? }
              @line_item.custom_price = custom_amount_opt&.[](:gift)&.[](:user_gift_amount).to_f
            end

            if @line_item.save
              @line_item.add_delivery_charges_to_price
              @line_item.pre_tax_amount = [@line_item.price, @line_item.custom_price].max
              @line_item.save
              @line_item.update_customizations customization_options
              render_serialized_payload { serialize_resource(@line_item) }
            else
              render_error_payload(failure(@line_item).error)
            end
          end

          def request_refund
            @line_item.refund_notes = params[:notes] if params[:notes].present?
            if @line_item.save
              spree_customer_email = @line_item.order.user.email
              # spree_customer_name = spree_current_user.id
              Spree::RefundRequestMailer.send_refund_request_mail(@line_item, spree_customer_email).deliver_now
              render_serialized_payload { serialize_resource(@line_item) }
            else
              render_error_payload(failure(@line_item).error)
            end
          end

          def bulk_update
            line_items = params["line_items"]
            if line_items
              line_items.each do |id, line_item_data|
                line_item = Spree::LineItem.find_by('spree_line_items.id = ?', id)
                line_item_data.permit!
                line_item_data = line_item_data.delete_if { |k, v| v.to_s.empty? && ['message', 'receipient_phone_number'].exclude?(k) }
                unless line_item.update(line_item_data)
                  render_error_payload(line_item.errors.full_messages[0], 422) and return
                end
              end
            end
            render_serialized_payload { success({success: true}).value }
          end

          def update_item
            return render json: {error: "You are not authorized to perform this action"} unless current_client.store_ids.include?(@line_item.order.store_id)
            if @line_item.update(line_items_params)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@line_item).error)
            end

          end

          def best_selling_report
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if @spree_current_user.present? && (@spree_current_user.spree_roles.map(&:name).include?"vendor")
              vendor = @spree_current_user.vendors.first
              base_currency = vendor&.base_currency&.name
              convert_to_currency = nil
              products = vendor.line_items.ransack(params[:q]).result(distinct: true)
            else
              base_currency = "USD"
              convert_to_currency = "USD"
              params[:q] = {} if params[:q].blank?
              params[:q][:vendor_id_in] = @spree_current_user&.client&.vendor_ids
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids if @spree_current_user.user_with_role("sub_client")
              products = params[:q][:vendor_id_in].present? ? Spree::LineItem.ransack(params[:q]).result(distinct: true) : Spree::LineItem.none
            end
            # products = products.select("SUM(spree_line_items.quantity) as total_qty, SUM(spree_line_items.sub_total * spree_line_items.quantity) as final_total, spree_line_items.store_id, spree_line_items.variant_id,spree_line_items.price, spree_line_items.currency, spree_line_items.order_id").joins("INNER JOIN spree_orders ON spree_orders.id = spree_line_items.order_id").where("spree_orders.state = 'complete'").group("spree_line_items.variant_id, spree_line_items.store_id, spree_line_items.price, spree_line_items.currency, spree_line_items.order_id")
            products = products.select("SUM(spree_line_items.quantity) as total_qty, SUM(spree_line_items.sub_total * spree_line_items.quantity) as final_total, spree_line_items.store_id, spree_line_items.variant_id, spree_line_items.vendor_name, spree_line_items.currency").joins("INNER JOIN spree_orders ON spree_orders.id = spree_line_items.order_id").where("spree_orders.state = 'complete'").group("spree_line_items.variant_id, spree_line_items.store_id, spree_line_items.vendor_name, spree_line_items.currency")
            all_products = products.map do  |p|
              next if p.variant.blank? || p.product.blank?
              {name: p&.name,store_name: p&.store&.name, sku: p&.sku, no_of_sales: p&.total_qty, total: sprintf('%.2f', p&.final_total), currency_symbol: Spree::Money.new(base_currency)&.currency&.symbol, vendor_name: p&.vendor_name, variant: p.variant.options_text, currency: p.currency}
            end.reject(&:blank?)
            final_data = {total_count: all_products.count}
            products = collection_paginator.new(all_products, params).call
            final_data[:data] = products
            render json: final_data.to_json
          end

          def get_csv
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            send_data Spree::LineItem.to_csv(@spree_current_user, params[:q]), filename: "best-selling-products-report-#{Date.today}.csv"
          end

          def upload_image
            img = Spree::Image.new(viewable_type: "Spree::LineItemCustomization", attachment_file_name: params[:file].original_filename)
            img.attachment.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
            if img.save
              serilizaed_image = Spree::V2::Storefront::ImageSerializer.new(img).serializable_hash
              render_serialized_payload { serilizaed_image }
            else
              render_error_payload(failure(img).error)
            end
          end

          def send_gift_cards_email
            if !@spree_current_user.user_with_role("customer_support")
              line_item = Spree::LineItem.find_by(id: params[:type].constantize.find_by(id: params[:id]).line_item_id)
              return render json: {error: "You are not authorized to perform this action"} unless current_client.store_ids.include?(line_item.order.store_id)
            end
            if params[:type] == "Spree::GivexCard"
              SesEmailsDataWorker.perform_async(params[:id], "digital_givex_card_recipient")
            elsif params[:type] == "Spree::TsGiftcard"
              SesEmailsDataWorker.perform_async(params[:id], "digital_ts_card_recipient")
            end
            render_serialized_payload { success({success: true}).value }
          end

          def send_gift_cards_sms
            if !@spree_current_user.user_with_role("customer_support")
              line_item = Spree::LineItem.find_by(id: params[:type].constantize.find_by(id: params[:id]).line_item_id)
              return render json: {error: "You are not authorized to perform this action"} unless current_client.store_ids.include?(line_item.order.store_id)
            end
            if params[:type] == "Spree::GivexCard"
              card = Spree::GivexCard.find_by('spree_givex_cards.id = ?', params[:id])
              SmsWorker.perform_async(card&.store.id, params[:receipient_phone_number], "Spree::GivexCard", params[:slug])
            elsif params[:type] == "Spree::TsGiftcard"
              card = Spree::TsGiftcard.find_by('spree_ts_giftcards.id = ?', params[:id])
              SmsWorker.perform_async(card&.store.id, params[:receipient_phone_number], "Spree::TsGiftcard", params[:slug])  
            end
            render_serialized_payload { success({success: true}).value }
          end

          def regenerate_gift_cards
            if params[:type] == "Spree::GivexCard"
              givex_card = Spree::GivexCard.find_by('spree_givex_cards.id = ?', params[:card_id])
              return render json: {error: ["Givex Card has already been generated"]}, status: :unprocessable_entity if givex_card.card_generated
              store = givex_card&.line_item&.store
              return render json: {error: ["Please add configurations for GiveX in store settings"]}, status: :unprocessable_entity if (store.givex_url.blank? && store.givex_secondary_url.blank?) || store.givex_user.blank? || store.givex_password.blank?
              givex_card.generate_card
              response = givex_card.reload.givex_response
            elsif params[:type] == "Spree::TsGiftcard"
              ts_card = Spree::TsGiftcard.find_by('spree_ts_giftcards.id = ?', params[:card_id])
              return render json: {error: ["Ts Card has already been generated"]}, status: :unprocessable_entity if ts_card.card_generated
              store = ts_card&.line_item&.store
              return render json: {error: ["Please add configurations for TS in store settings"]}, status: :unprocessable_entity if store.ts_gift_card_url.blank? || store.ts_gift_card_email.blank? || store.ts_gift_card_password.blank?
              ts_card.generate_card
              response = ts_card.reload.response
            end
            render_serialized_payload { success({response: response}).value }
          end

          private
          
          def validate_processable_card
            card = params[:type].constantize.find_by('id = ?', params[:card_id])
            render json: {error: ["Card has already been in process"]}, status: :unprocessable_entity unless card.processable?
          end

          def delete_cache_for_lineitem
            @line_item.store.clear_store_cache()
          end

          def set_line_item
            @line_item = Spree::LineItem.find_by('spree_line_items.id = ?', params[:id])
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::LineItemSerializer.new(
              resource,
              params: {default_currency: current_currency}
            ).serializable_hash
          end

          def resource
            Spree::LineItem.find_by('spree_line_items.id = ?', params[:id])
          end

          def line_items_params
            params[:line_item].permit(:status)
          end

          def ensure_term_agreed
            render_error_payload(I18n.t('order.line_item.agree_to_email_change'), 403) unless params[:line_item][:agree] === 'acknowledged'
          end

          def ensure_lead
            render_error_payload("You are not Authorized for this action", 403) unless @spree_current_user.lead?
          end

          def update_recipient_params
            params.require(:line_item).permit(email_changes_attributes: [:user_id, :previous_email, :next_email, :note])
          end

        end
      end
    end
  end
end
