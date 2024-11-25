module Spree
  module Api
    module V2
      module Storefront
        class FulfilmentInfoController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2
          before_action :require_spree_current_user, :authorize_client_or_sub_client
          before_action :set_shipment, except: [:show,:marked_as_fulfiled]
          before_action :set_fulfilment_info, except: [:index, :create]
          before_action :set_report_infos, only: [:index]
          before_action :unauthorized_roles_except_fulfilment
          before_action :check_permissions

          def index
            infos = collection_paginator.new(@fulfilment_infos, params).call
            render_serialized_payload { serialize_collection(infos ,Spree::V2::Storefront::FulfilmentInfoSerializer) }
          end

          def show
            render_serialized_payload { serialize_resource(@fulfilment_info,Spree::V2::Storefront::FulfilmentInfoSerializer) }
          end

          def update
            if @shipment.fulfilment_info.update(fulfilment_info_params.merge({user_id: spree_current_user.id}))
              render_serialized_payload { serialize_resource(@fulfilment_info,Spree::V2::Storefront::FulfilmentInfoSerializer) }
            else
              render_error_payload(failure(@fulfilment_info).error)
            end
          end

          def marked_as_fulfiled
            if @fulfilment_info.original?
              @fulfilment_info&.shipment&.update_column(:fulfilment_status, :fulfiled)
            elsif @fulfilment_info.replacement?
              replacement_info = @fulfilment_info.replacement_info || {}
              replacement_info["state"] = 'fulfiled'
              @fulfilment_info.update_column(:replacement_info, replacement_info)
            end
            @fulfilment_info.update_column(:state, :fulfiled)
          end

          def create
            fulfilment_info = @shipment.build_fulfilment_info(fulfilment_info_params.merge({user_id: spree_current_user.id}))
            if fulfilment_info.save
              render_serialized_payload { serialize_resource(fulfilment_info,Spree::V2::Storefront::FulfilmentInfoSerializer) }
            else
              render_error_payload(failure(fulfilment_info).error)
            end
          end

          def create_replacement
            return render_error_payload("Can't make more replacements, reached limit.", 422) if @fulfilment_info&.replacements&.count >= 5
            replacement_info = @fulfilment_info.replacements.any? ?
                                   @fulfilment_info.replacements.build(fulfilment_info_params) :
                                   @fulfilment_info.build_replacement(fulfilment_info_params)

            replacement_info.assign_attributes(user_id: spree_current_user.id, shipment_id: @shipment.id, info_type: 1)
            if replacement_info.save(validate: false)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(I18n.t('fulfilment.replacement.create_fail'), 422)
            end
          end

          def update_replacement
            if @fulfilment_info.replacement? && @fulfilment_info.update_columns(fulfilment_info_params.to_h.merge(user_id: spree_current_user.id))
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(I18n.t('fulfilment.replacement.update_fail'), 422)
            end
          end


          private

          def set_fulfilment_info
            @fulfilment_info = Spree::FulfilmentInfo.find_by('spree_fulfilment_infos.id = ?', params[:id])
            render_error_payload('Record not found', 404) unless @fulfilment_info.present?
          end

          def fulfilment_info_params
            params[:fulfilment_info].permit(:gift_card_number, :serial_number, :currency, :customer_shippment_paid, :processed_date, :postage_currency, :postage_fee, :receipt_reference, :courier_company, :tracking_number, :comment, :accurate_submition, :shipment_id, :original_id, replacement_info: {})
          end


          def set_shipment
            @shipment = Spree::Shipment.find_by('spree_shipments.id = ?', params[:shipment_id])
          end

          def set_report_infos
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            params[:q] = params[:q].merge(shipment_fulfilment_status_eq: 'fulfiled', shipment_delivery_mode_in: ['givex_physical', 'tsgift_physical'])
            @fulfilment_infos = Spree::FulfilmentInfo.store_fulfilment_infos.fulfiled.ransack(params[:q]).result.sorted_infos
          end
        end
      end
    end
  end
end
