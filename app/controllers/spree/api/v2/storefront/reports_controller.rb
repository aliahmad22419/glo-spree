module Spree
  module Api
    module V2
      module Storefront
        class ReportsController < ::Spree::Api::V2::BaseController
          
          before_action :require_spree_current_user


          def create
            report = current_client.reports.new(report_params)
            if report.save
              ReportWorker.perform_async(report)
              render_serialized_payload { serialize_resource(report) }
            else
              render_error_payload(failure(report).error)
            end
          end

          def report_params
            params.require(:report).permit(:feed_type, :email, :attachment, :store_id)
          end

        end  
      end
    end
  end
end
