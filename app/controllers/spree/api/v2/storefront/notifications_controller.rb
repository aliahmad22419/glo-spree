module Spree
  module Api
    module V2
      module Storefront
        class NotificationsController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :set_vendor
          before_action :set_notification, only: [:destroy, :mark_as_read]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            q = @vendor.notifications.ransack(params[:q])
            notifications = q.result
            notifications = collection_paginator.new(notifications, params).call
            render_serialized_payload { serialize_collection(notifications) }
          end

          def create
            notification = current_client.notifications.new(message: params[:message], vendor_ids: params[:vendor_ids])
            notification.store_id = spree_current_store&.id
            if notification.save
              render_serialized_payload { serialize_resource(notification) }
            else
              render_error_payload(failure(notification).error)
            end
          end

          def mark
            notification = @vendor.notifications_vendors.find_by('spree_notifications_vendors.notification_id = ?', params[:id])
            if notification.update(read: true)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(notification).error)
            end
          end

          def mark_multiple
            notifications = @vendor.notifications_vendors.where('spree_notifications_vendors.notification_id IN (?)',
                                                                JSON.parse(params[:ids]))
            if notifications.update_all(read: true)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(notifications).error)
            end
          end

          def destroy
            if @notification.destroy
              render_serialized_payload { serialize_resource(@notification) }
            else
              result = failure(@notification)
              render_error_payload(result.error)
            end
          end

          def destroy_multiple
            notifications = @vendor.notifications.where('spree_notifications.id IN (?)', JSON.parse(params[:ids]))
            if notifications.destroy_all
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(notifications).error)
            end
          end

          private

          def valid_json?(json)
            begin
              JSON.parse(json)
              return true
            rescue Exception => e
              return false
            end
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::NotificationSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::NotificationSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def collection_options(collection)
            {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: resource_includes,
              fields: sparse_fields,
              params: {
                vendor_id: @vendor.id
              }
            }
          end

          def set_notification
            @notification = @vendor.notifications.find_by('spree_notifications.id = ?', params[:id])
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @notification
          end

          def set_vendor
            @vendor = @spree_current_user.vendors.first
          end

          def notification_params
            params.require(:notification).permit(:message, vendor_ids: [])
          end

        end
      end
    end
  end
end
