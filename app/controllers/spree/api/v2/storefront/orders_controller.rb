module Spree
  module Api
    module V2
      module Storefront
        class OrdersController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:update_currency, :download_apple_pass, :subscribe_marketing_data]
          before_action :check_permissions
          before_action :set_order, only: [:show, :update, :destroy, :send_email_to_customer, :invoice, :send_emails, :update_shipment_card_schedule, :update_notes, :download_order_gift_cards]
          before_action :ensure_customer_support_lead, only: [:refund]

          def invoice
            @bookkeeping_document = @order.bookkeeping_documents.create(template: 'invoice', vendor_id: params[:vendor_id], old_invoice: params[:old_invoice], shipment_id: params[:shipment_id])
            File.open(@bookkeeping_document.file_path, 'wb') { |f| f.puts @bookkeeping_document.render_pdf }
            send_data @bookkeeping_document.render_pdf, type: 'application/pdf', disposition: 'inline'
          end

          def csv_details
            @order = @spree_current_user.orders.complete.find_by(number: params[:number])
            send_data @order.csv_details, filename: "#{@order.number}.csv"
          end

          def download_report
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if @spree_current_user.user_with_role("sub_client")
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids
            end
            filename = params[:report_name].present? ? params[:report_name] : "total-sales-report-#{Date.today}"

            options = {
              user:  @spree_current_user,
              method: :to_csv,
              q: params[:q],
              filename: filename
            }
            archive = CsvReports.send(:download_csv, options)
            send_file archive, type: 'application/zip', disposition: 'inline'
          end

          def download_order_gift_cards
            filename = "order-gift-cards-report-#{Date.today}"

            options = {
              user: @spree_current_user,
              method: :order_card_details,
              q: {order: @order, filename: @order.number},
              filename: filename
            }
            archive = CsvReports.send(:download_csv, options)
            send_file archive, type: 'application/zip', disposition: 'inline'
          end

          def download_ppi_report
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if @spree_current_user.user_with_role("sub_client")
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids
            end
            filename = params[:q][:show_ppi].eql?('true') ? "sales-including-pii-report-#{Date.today}" : "sales-excluding-pii-report-#{Date.today}"

            options = {
              user:  @spree_current_user,
              method: :to_csv,
              q: params[:q],
              filename: filename
            }
            archive = PpiReports.send(:download_csv, options)
            send_file archive, type: 'application/zip', disposition: 'inline'
          end

          def download_report_finance_sale
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if @spree_current_user.user_with_role("sub_client")
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids
            end
            filename = "finance-sale-report-#{Date.today}"

            options = {
              user:  @spree_current_user,
              method: :to_csv_finance,
              q: params[:q],
              filename: filename
            }
            archive = CsvReports.send(:download_csv, options)
            send_file archive, type: 'application/zip', disposition: 'inline'
          end

          def download_ts_givex_sale_report
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if @spree_current_user.user_with_role("sub_client")
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids
            end
            filename = "ts-givex-sales-report-#{Date.today}"

            options = {
              user:  @spree_current_user,
              method: :ts_givex_sales_csv,
              q: params[:q],
              filename: filename
            }
            archive = CsvReports.send(:download_csv, options)
            send_file archive, type: 'application/zip', disposition: 'inline'
          end

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            total_amount = 0
            if @spree_current_user.spree_roles.map(&:name).include?"vendor"
              vendor = @spree_current_user.vendors.first
              params[:q] = {} if params[:q].blank?
              params[:q][:shipments_vendor_id_eq] = vendor.id
              orders = Spree::Order.complete.ransack(params[:q]).result(distinct: true).order("completed_at DESC")
              #set attribute for vendor dashboard reports
              if params[:q][:vendor_dashboard].present?
                vendor_base_currency = vendor&.base_currency&.name
                vendor_dashboard = true
                # total_amount = "%.2f" % orders.sum{|o| o.float_tp(o.price_values(vendor_base_currency || o.currency, vendor.id)[:prices][:payable_amount], (vendor_base_currency || o.currency)) }
              end
              orders = collection_paginator.new(orders, params).call
              render_serialized_payload { serialize_collection(orders, vendor_dashboard, vendor_base_currency, total_amount) }
            elsif (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              params[:q] = {} if params[:q].blank?
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids if @spree_current_user.user_with_role("sub_client")
              params[:q][:shipments_vendor_id_in] = @spree_current_user&.client&.vendor_ids
              orders = params[:q][:shipments_vendor_id_in].present? ? Spree::Order.complete.ransack(params[:q]).result(distinct: true).order("completed_at DESC") : Spree::Order.none
              # total_amount = "%.2f" % orders.sum{|o| o.float_tp(o.price_values("SGD", nil)[:prices][:payable_amount], 'SGD') }
              orders = collection_paginator.new(orders, params).call
              render_serialized_payload { serialize_collection(orders,true, "SGD", total_amount) }
            else
              params[:q] = params[:q].split(',') if params[:q].include? "returned"
              orders = @spree_current_user.orders.complete.ransack(params[:q]).result.order("completed_at DESC")
              render_serialized_payload { serialize_collection_without_pagination(orders) }
            end
          end

          def ts_giftcard_givex
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              params[:q] = {} if params[:q].blank?
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids if @spree_current_user.user_with_role("sub_client")
              params[:q][:shipments_vendor_id_in] = @spree_current_user&.client&.vendor_ids
              order_list = Spree::Order.complete.ransack(params[:q]).result(distinct: true)
              order_ids = order_list.joins(:ts_giftcards).ids + order_list.joins(:givex_cards).ids
              orders = Spree::Order.where('id IN (?)', order_ids).order("completed_at DESC")
              orders = params[:q][:shipments_vendor_id_in].present? ? orders : Spree::Order.none
              total_amount = 0
              # total_amount = "%.2f" % orders.sum{|o| o.float_tp(o.price_values("SGD", nil)[:prices][:payable_amount], 'SGD') }
              orders = collection_paginator.new(orders, params).call
              render_serialized_payload { serialize_collection(orders,true, "SGD", total_amount) }
            end
          end

          def dashboard_orders
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            params[:q] = {} if params[:q].blank?
            if @spree_current_user.spree_roles.map(&:name).include?"vendor"
              vendor = @spree_current_user.vendors.first
              params[:q][:shipments_vendor_id_eq] = vendor.id
              orders = Spree::Order.complete.ransack(params[:q]).result(distinct: true).order("completed_at DESC")
            elsif (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              params[:q][:store_id_in] =  @spree_current_user.allow_store_ids if @spree_current_user.user_with_role("sub_client")
              params[:q][:shipments_vendor_id_in] = @spree_current_user&.client&.vendor_ids
              orders = params[:q][:shipments_vendor_id_in].present? ? Spree::Order.complete.ransack(params[:q]).result(distinct: true).order("completed_at DESC") : Spree::Order.none
            end
            orders = collection_paginator.new(orders, params).call
            render_serialized_payload { serialize_collection(orders) }
          end

          def search_orders_customer_service
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            params[:q] = {} if params[:q].blank?
            digits = params[:q].delete('payments_source_of_Spree::CreditCard_type_last_digits_eq')
            combined_q = params[:q].to_unsafe_hash

            if digits.present?
              digits_q = {
                'payments_source_of_Spree::CreditCard_type_last_digits_eq' => digits,
                'payments_state_eq' => 'completed',
                'm' => 'and'
              }
              combined_q = {groupings: [combined_q, digits_q], 'm' => 'and'}
            end

            orders = Spree::Order.complete.ransack(combined_q).result(distinct: true).order("completed_at DESC")
            orders = collection_paginator.new(orders, params).call
            render_serialized_payload { serialize_collection(orders) }
          end

          def update
            if @order.update(order_params)
              @order.update_sale_analyses
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@order).error)
            end
          end

          def show
            render_serialized_payload { serialize_resource(@order) }
          end

          def update_shipment_card_schedule
            render_error_payload("Shipment not found") and return if params[:shipmentId].nil?
            shipment = @order.shipments.find_by('spree_shipments.id = ?', params[:shipmentId])
            new_schedule_datetime = Time.find_zone('UTC').parse(params[:scheduledAt])
            shipment.update_column(:card_generation_datetime, new_schedule_datetime)
            render_serialized_payload { success({success: true }).value }
          end

          def update_currency
            if order = Spree::Order.find_by(token: params[:order_token])
              if order.update(currency: params[:currency].strip)
                render_serialized_payload { success({success: true }).value }
              else
                render_error_payload(failure(order).error)
              end
            else
              render_error_payload("Something went wrong while updating currency!")
            end
          end

          def update_notes
            if @order.update(notes: params[:order][:notes])
              render_serialized_payload { serialize_resource(@order) }
            else
              render_error_payload(@order.errors.full_messages[0], 422)
            end
          end

          def mark_status
            status = params[:status]
            stipment = Spree::Shipment.find_by('spree_shipments.id = ?', params[:id])
            if status == "acknowledged"
              if stipment.can_acknowledged?
                stipment.acknowledged!
                render_serialized_payload { success({success: true }).value }
              else
                render_error_payload(failure(stipment, "Payment is not cleared Or You cant not revert status").error)
              end
            elsif status == "processing"
              if stipment.can_processing?
                stipment.processing!
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(stipment, "Order is not acknowledged and payment is not cleared(Or You cant not revert status)").error)
              end
            elsif status == "shipped"
              if stipment.can_shipped?
                stipment.update_attribute(:tracking, params[:tracking])
                stipment.shipped!
                render_serialized_payload { success({success: true, shipped_at: stipment.shipped_at}).value }
              else
                render_error_payload(failure(stipment, "Not Allowed. Already marked shipped.").error)
              end
            end
          end

          def send_emails
            @order.send_order_emails
            render_serialized_payload { success({success: true}).value }
          end

          def send_email_to_customer
            message = params[:message]
            vendor = @spree_current_user.vendors.first
            vendor_email = vendor&.email
            cus_email = @order&.email
            logo_url = vendor&.client&.active_storge_url(vendor&.client&.logo)
            Spree::GeneralMailer.send_order_email_to_customer(cus_email,vendor_email, message, logo_url, @order&.store).deliver_now if cus_email.present?
            render_serialized_payload { success({success: true}).value }
          end

          def refund
            refund = Spree::Refund.new(refund_params.merge(user_id: spree_current_user.id))

            begin
              if refund.save
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(refund).error)
              end
            rescue Exception => e
              render json: { error: e.message }, status: :unprocessable_entity
            end
          end

          def download_apple_pass
            gift_card = params[:card_type].constantize.find_by(id: params[:card_id])

            @pass_file_name = gift_card.line_item.product.name&.split()&.collect(&:capitalize)&.join&.first(30)
            @pass_file_name ||= gift_card.store.name.split().collect(&:capitalize).join

            send_data open(gift_card.pk_pass.service_url).read, filename: "#{@pass_file_name}.pkpass", disposition: "attachment"
          end

          def update_order_spread_sheet
            Spree::UpdateOrderSpreadSheet.new(params[:id],ENV['GOOGLESHEET_UPDATE_QUEUE_URL'],"Update Googlesheet Data").update_sheet
          end

          def subscribe_marketing_data
            order = Spree::Order.find_by('spree_orders.id = ?', params[:id])
            return render_error_payload("Order Not Found...!", 404) unless order.present?
            order.update(marketing_params)
            render_serialized_payload { success({success: true}).value }
          end

  

          private

          def serialize_collection_without_pagination(collection)
            Spree::V2::Storefront::OrderSerializer.new(
                collection,
                {
                    fields: sparse_fields
                }
            ).serializable_hash
          end

          def serialize_collection(collection, dashboard = false, base_currency = nil, total_amount = 0)
            Spree::V2::Storefront::OrderSerializer.new(
              collection,
              collection_options(collection, dashboard,  base_currency, total_amount)
            ).serializable_hash
          end

          def collection_options(collection, dashboard, base_currency, total_amount)
            vendor_id = @spree_current_user&.vendors&.first&.id
            meta_data = collection_meta(collection)
            meta_data[:total_amount] = total_amount if dashboard
            {
                links: collection_links(collection),
                meta: meta_data,
                include: resource_includes,
                fields: sparse_fields,
                params: {vendor_base_currency: base_currency, vendor_dashboard: dashboard, vendor_id: vendor_id }
            }
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::OrderSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields,
                params: {default_currency: resource.currency, vendor_id: @spree_current_user&.vendors&.first&.id, current_user: @spree_current_user}
            ).serializable_hash
          end

          def set_order
            if @spree_current_user.spree_roles.map(&:name).include?"vendor"
              @order = Spree::Order.complete.ransack({line_items_vendor_id_eq: @spree_current_user.vendors.first.id}).result.find_by('spree_orders.id = ?', params[:id])
            elsif @spree_current_user.user_with_role("client")
              @order = Spree::Order.complete.ransack({line_items_vendor_id_in: @spree_current_user&.client&.vendor_ids}).result.find_by('spree_orders.id = ?', params[:id])
            elsif @spree_current_user.user_with_role("sub_client")
              @order = Spree::Order.complete.ransack({line_items_vendor_id_in: @spree_current_user&.client&.vendor_ids}).result&.where(store_id: @spree_current_user&.allow_store_ids)&.find_by('spree_orders.id = ?', params[:id])
            elsif (@spree_current_user.user_with_role("customer_support"))
              @order = Spree::Order.complete.find_by('spree_orders.id = ?', params[:id])
            elsif (["fulfilment_user","fulfilment_admin","fulfilment_super_admin"].include?(@spree_current_user.spree_roles.first.name))
              @order = Spree::Order.accessible_by(current_ability).find_by('spree_orders.id = ?', params[:id])
              render_error_payload("Resource you are looking for could not be found") and return unless @order&.store&.allow_fulfilment?
            else
              @order = @spree_current_user.orders.complete.find_by('spree_orders.id = ?', params[:id])
            end

            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @order
          end

          def valid_json?(json)
            begin
              JSON.parse(json)
              return true
            rescue Exception => e
              return false
            end
          end

          def order_params
            params.require(:order).permit(:order_tag_ids => [])
          end

          def ensure_customer_support_lead
            unless spree_current_user.user_with_role('customer_support') && spree_current_user.lead
              render_error_payload("You are not Authorized", 403)
            end
          end

          def refund_params
            params.permit(:amount, :notes, :order_id, :user_id, :payment_refund_type)
          end

          def marketing_params
            params.permit(:news_letter, :enabled_marketing)
          end
        end
      end
    end
  end
end
