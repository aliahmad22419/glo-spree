module Spree
  module Api
    module V2
      module Storefront
        class ReimbursementsController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user

          def update_status
            status = params[:status]
            reimbursement = Spree::Reimbursement.find_by('spree_reimbursements.id = ?', params[:id])

            if status == "1"
              reimbursement.pending!
              render_serialized_payload { success({success: true}).value }
            else
              reimbursement.completed!
              render_serialized_payload { success({success: true}).value }
            end
          end
        end
      end
    end
  end
end
