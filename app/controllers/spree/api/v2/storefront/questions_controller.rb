module Spree
  module Api
    module V2
      module Storefront
        class QuestionsController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user, :if => Proc.new{ params[:access_token] }
          before_action :check_permissions
          before_action :set_question, only: [:show, :update, :destroy, :reply]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            q = questions.ransack(params[:q])
            questions = q.result.order("id DESC")
            questions = collection_paginator.new(questions, params).call
            render_serialized_payload { serialize_collection(questions) }
          end

          def show
            render_serialized_payload { serialize_resource(@question) }
          end

          def reply
            answer = @question.answer
            answer = @question.build_answer if answer.nil?
            answer.title = params[:answer]
            if answer.save
              @question.update_column(:is_replied, true)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(answer).error)
            end
          end

          def update
            if @page.update(page_params)
              render_serialized_payload { serialize_resource(@page) }
            else
              render_error_payload(failure(@page).error)
            end
          end

          def create
            params[:question] = JSON.parse(params[:question]) if params[:question].present? && valid_json?(params[:question])

            if params[:question]["store_id"].present?
              question = Spree::Question.new(question_params)
            else
              question = Spree::Question.new(question_params.merge({store_id: spree_current_store&.id}))
            end

            if question.save
              render_serialized_payload { serialize_resource(question) }
            else
              render_error_payload(failure(question).error)
            end
          end

          def destroy
            if @page.destroy
              render_serialized_payload { serialize_resource(@page) }
            else
              render_error_payload(failure(@page).error)
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
            Spree::V2::Storefront::QuestionSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::QuestionSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_question
            @question = questions.find_by('spree_questions.id = ?', params[:id])
            return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @question
          end

          def questions
            @questions = if @spree_current_user.present? && @spree_current_user.user_with_role("vendor")
                          @spree_current_user.vendors.first.questions
                        elsif @spree_current_user.nil?
                          Spree::Question.where(store_id: spree_current_store&.id)
                        else
                          Spree::Question.accessible_by(current_ability, :index)
                        end
          end

          def question_params
            params.require(:question).permit(:title, :is_replied, :archived, :vendor_id, :product_id, :status, :guest_email, :guest_name, :customer_id, :questionable_type, :questionable_id, :store_id)
          end

        end
      end
    end
  end
end
