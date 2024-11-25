module Spree
  module Api
    module V2
      module Storefront
        class AwsFilesController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, :require_spree_current_client
          before_action :check_permissions
          before_action :set_aws_file, only: [:destroy]
          # before_action :check_xss_injection, only: [:create]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            aws_files = current_client.aws_files.ransack(params[:q]).result.order("created_at DESC")
            aws_files = collection_paginator.new(aws_files, params).call
            render_serialized_payload { serialize_collection(aws_files) }
          end
        
          def create
            file_asset = current_client.aws_files.new(created_by_id: @spree_current_user.id)
            file_asset.attachment.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
            if file_asset.save
              render_serialized_payload { success({success: true, aws_file_id: file_asset.id}).value  }
            else
              render_error_payload(failure(@aws_file).error)
            end
          end

          def update
            @aws_file = Spree::AwsFile.unscoped.find_by('id = ? AND client_id = ?', params[:id], current_client.id)
            if @aws_file.update(aws_file_params.merge({ active: true }))            
              render_serialized_payload { @aws_file }
            else
              render_error_payload(failure(@aws_file).error)
            end
          end
        
          def destroy
            if @aws_file.destroy
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@aws_file).error)
            end
          end
        
          private

          def serialize_collection(collection)
            Spree::V2::Storefront::AwsFileSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def set_aws_file
            @aws_file = current_client.aws_files.find_by('spree_aws_files.id = ?', params[:id])
            return render json: { error: "Resource you are looking for could not be found" }, status: :not_found unless @aws_file.present?
          end
        
          def aws_file_params
            params.require(:aws_file).permit(:name, :url, :comment)
          end

          def check_xss_injection
            content = params[:file].read
            return render json: { error: "Forbidden Entity, content not allowed" }, status: 405 if forbidden_tag_exist? content.to_s
          end
        end
      end
    end    
  end
end