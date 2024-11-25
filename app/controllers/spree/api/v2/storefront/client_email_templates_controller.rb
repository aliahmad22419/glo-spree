module Spree
  module Api
    module V2
      module Storefront
        class ClientEmailTemplatesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :set_email_templates, only: [:update]
					before_action :check_permissions


          def index
            email_templates = Spree::EmailTemplate.where(client_id: current_client.id)
            render_serialized_payload { serialize_collection(email_templates) }
          end

          def create
            email_template = Spree::EmailTemplate.new(email_templates_params.merge({ client_id: current_client.id }))
            email_template.name = "#{email_template.email_type}_client_#{ENV['SES_ENV']}_#{current_client.id.to_s}"
            if email_template.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(email_template).error)
            end
          end

          def update
            @email_templates.name = "#{@email_templates.email_type}_client_#{ENV['SES_ENV']}_#{current_client.id.to_s}"
            if @email_templates.update(email_templates_params)
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@email_templates).error)
            end
          end

          def send_sample_email
            email_type = params[:email_type]
            render_error_payload("Please specify email type", 400) and return if email_type.blank?
            
            report = current_client.scheduled_reports.find_by(report_type: email_type)
            report = if report.blank?
              ScheduledReport.where(reportable_type: 'Spree::Store', reportable_id: current_client.stores.ids)[0]
            end
            render_error_payload("No recent scheduled report '#{email_type}'", 404) and return if report.blank?

            Spree::Scheduled::ReportGenerator.new(report.id).generate
            render_serialized_payload { success({success: true}).value  }
          end

          private

          def serialize_collection(collection)
            Spree::V2::Storefront::EmailTemplateSerializer.new(collection).serializable_hash
          end

          def set_email_templates
            @email_templates = Spree::EmailTemplate.find_by('spree_email_templates.client_id = ? AND spree_email_templates.id = ?', current_client.id, params[:id])
            return render json: { error: "Client email template not found" }, status: 403 unless @email_templates
          end

          def email_templates_params
            params[:client_email_template].permit(:name, :subject, :email_text, :html, :email_type)
          end
        end
      end
    end
  end
end
