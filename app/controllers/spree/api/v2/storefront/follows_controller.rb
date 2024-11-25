module Spree
  module Api
    module V2
      module Storefront
        class FollowsController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :set_question, only: [:show, :update, :destroy]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            follow_requests = @spree_current_user.followed_users
            q = follow_requests.ransack(params[:q])
            follow_requests = q.result.order("id DESC")
            follow_requests = collection_paginator.new(follow_requests, params).call
            render_serialized_payload { serialize_collection(follow_requests) }
          end

          def show
            render_serialized_payload { serialize_resource(@follow) }
          end

          def update
            if @follow.update(page_params)
              render_serialized_payload { serialize_resource(@follow) }
            else
              render_error_payload(failure(@follow).error)
            end
          end

          def create
            follow = Spree::Follow.new(question_params.merge({followee_id: @spree_current_user&.id}))
            if follow.save
              render_serialized_payload { serialize_resource(follow) }
            else
              render_error_payload(failure(follow).error)
            end
          end

          def destroy
            if @follow.destroy
              render_serialized_payload { serialize_resource(@follow) }
            else
              render_error_payload(failure(@follow).error)
            end
          end

          def approve
            requests = Spree::Follow.not_approved.where('spree_follows.id IN (?)', JSON.parse(params[:ids]))
            requests.each{|x| x.update(status: 'approved')}
            render_serialized_payload { success({success: true}).value }
          end

          def reject
            requests = Spree::Follow.not_rejected.where('spree_follows.id IN (?)', JSON.parse(params[:ids]))
            requests.each{|x| x.update(status: 'rejected')}
            render_serialized_payload { success({success: true}).value }
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
            Spree::V2::Storefront::FollowSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::FollowSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_question
            @follow = Spree::Follow.find_by('spree_follows.id = ?', params[:id])
          end

          def question_params
            params.require(:follow).permit(:follower_id, :followee_id, :name, :email, :details, :status, :website, :instagram, :country_name)
          end

        end
      end
    end
  end
end
