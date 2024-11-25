module Spree
  module Api
    module V2
      module Storefront
        class HomesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_attachable, only: [:attach_image_file]
					before_action :authorized_client_sub_client, only: [:update_scheduled_reports]

          def attach_image
            img = Spree::Image.new(viewable_type: params[:viewable_type], viewable_id: params[:viewable_id], attachment_file_name: params[:file].original_filename)
            img.attachment.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
            if img.save!
              serilizaed_image = Spree::V2::Storefront::ImageSerializer.new(img).serializable_hash
              render_serialized_payload { serilizaed_image }
            else
              render_error_payload(failure(img).error)
            end
          end

          def upload_image
            img = Spree::Image.new(viewable_type: params[:viewable_type], attachment_file_name: params[:file].original_filename)
            img.attachment.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
            if img.save!
              serilizaed_image = Spree::V2::Storefront::ImageSerializer.new(img).serializable_hash
              render_serialized_payload { serilizaed_image }
            else
              render_error_payload(failure(img).error)
            end
          end

          def attach_image_file
            if @attachable.present?
              # @attachable.send("#{params[:attachment]}=", params[:file])
              @attachable.send(params[:attachment]).attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
              if @attachable.save
                if params["alt"].present?
                  @attachable.logo.attachment.alt = params["alt"]
                  @attachable.logo.attachment.save
                end
                render json: { file_name: params[:file].original_filename, url: @attachable.active_storge_url(@attachable.send(params[:attachment])) }, status: 200
              else
                render json: { error: @attachable.errors.full_messages[0] }, status: :unprocessable_entity
              end
            end
          end

          def update_scheduled_reports
            @reportable = params[:reportable_type].constantize.find_by(id: params[:id])

            if @reportable.update(report_schedule_params)
              render_serialized_payload { success({reports: @reportable.reload.scheduled_reports, success: true}).value  }
            else
              render_error_payload(failure(@reportable).error)
            end
          end

          private

          def set_attachable
            v_type = params[:attachable_type]
            v_id = params[:attachable_id]
            if v_type == "Spree::Product"
              @attachable = v_type.constantize.find_by({:slug => v_id})
            else
              @attachable = v_type.constantize.find_by(id: v_id) rescue nil
            end
          end

          def report_schedule_params
            params[:reportable]
              .permit(scheduled_reports_attributes: [:id, :report_type, :scheduled_on, :password, :start_date, :end_date, :_destroy, store_ids: [], ts_store_ids: [], preferences: {}])
          end
        end
      end
    end
  end
end
