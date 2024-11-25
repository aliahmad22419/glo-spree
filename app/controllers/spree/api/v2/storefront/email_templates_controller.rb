module Spree
  module Api
    module V2
      module Storefront
        class EmailTemplatesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_store
          before_action :set_email_templates, only: [:update, :destroy]
					before_action :check_permissions


          def index
            email_templates = @store.email_templates
            render_serialized_payload { serialize_collection(email_templates) }
          end

          def create
            email_template = @store.email_templates.new(email_templates_params)
            email_template.name = email_template.email_type + "_store_" + ENV['SES_ENV'] + "_" + @store.id.to_s
            if email_template.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(email_template).error)
            end
          end

          def update
            @email_templates.name = @email_templates.email_type + "_store_" + ENV['SES_ENV'] + "_" + @store.id.to_s
            if @email_templates.update(email_templates_params)
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@email_templates).error)
            end
          end

          def destroy
            if @email_templates.destroy
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@email_templates).error)
            end
          end

          def send_sample_email
            email_type = params[:email_type]
            if email_type == "order_confirmation_customer" || email_type == "order_confirmation_vendor"
              resource_id = @store&.orders&.complete&.last&.id
            elsif email_type == "regular_shipment_customer"
              resource_id = @store&.orders&.complete&.last&.shipments&.last&.id
            elsif email_type == "voucher_confirmation_customer" || email_type == "voucher_confirmation_recipient"
              resource_id = Spree::GiftCard.last&.id
            elsif email_type == "digital_ts_card_recipient"
              resource_id = Spree::TsGiftcard.last&.id
            end
            SesEmailsDataWorker.perform_async(resource_id, email_type)
            render_serialized_payload { success({success: true}).value  }
          end

          private

            def serialize_resource(resource)
              Spree::V2::Storefront::EmailTemplateSerializer.new(resource).serializable_hash
            end

            def serialize_collection(collection)
              Spree::V2::Storefront::EmailTemplateSerializer.new(collection).serializable_hash
            end

            def set_store
              @store = current_client.stores.find_by('spree_stores.id = ?', params[:my_store_id])
            end

            def set_email_templates
              @email_templates = @store.email_templates.find_by('spree_email_templates.id = ?', params[:id])
              return render json: { error: "Email template not found" }, status: 403 unless @email_templates
            end

            def email_templates_params
              params[:email_template].permit(:name,
                                      :subject,
                                      :email_text,
                                      :html,
                                      :email_type
                                     )
            end
        end
      end
    end
  end
end
