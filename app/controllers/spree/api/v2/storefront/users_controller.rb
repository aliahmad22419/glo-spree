module Spree
  module Api
    module V2
      module Storefront
        class UsersController < ::Spree::Api::V2::BaseController
          # rescue_from Spree::Core::DestroyWithOrdersError, with: :error_during_processing
          before_action :require_spree_current_user, only: [:update, :destroy, :show, :create_fd_user, :create_sub_client, :index, :update_user, :user_account,:profile, :merge_cart, :cart, :search_bar_taxons, :scheduled_reports]
          before_action :check_permissions
          before_action :set_user, only: [:destroy, :update, :show]
          before_action :otp_user, only: [:send_otp_email, :verify_otp]
          skip_before_action :unauthorized_frontdesk_user, only:[:profile,:send_otp_email,:verify_otp,:get_user_roles]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            users = Spree::User.accessible_by(current_ability, :index).where.not(id: @spree_current_user.id).ransack(params[:q]).result.order("created_at DESC")
            users = collection_paginator.new(users, params).call
            render_serialized_payload { serialize_collection(users) }
          end

          def show
            authorize! :show, @user if @user.spree_roles.map(&:name).include?('sub_client')
            render_serialized_payload { Spree::V2::Storefront::SubClientSerializer.new(@user).serializable_hash }
          end

          def create # creates customer
            authorize! :create, Spree.user_class

            @user = Spree.user_class.new(user_params.merge({store_id: spree_current_store.id}))
            role = Spree::Role.find_by_name "customer"
            @user.spree_roles << role

            if @user.save
              spree_current_store.mailchimp_subscription(@user) if spree_current_store.mailchimp_setting.present?
              associate_cart_with_user
              render_serialized_payload { serialize_resource(@user) }
            else
              render_error_payload(@user.errors.full_messages[0], 403)
            end
          end

          def create_sub_client
            spree_authorize! :create_sub_client, Spree::User
            # in case of fufilment users current_client doesn't exit
            user = current_client ? current_client.users.new(user_params) : Spree::User.new(user_params)
            role = Spree::Role.find_by(name: params[:role])
            user.spree_roles << role

            if user.save
              user.generate_spree_api_key!
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(user.errors.full_messages[0], 403)
            end
          end

          def create_fd_user # creates front_desk users
            spree_authorize! :create_fd_user, Spree::User
            user = current_client.users.new(user_params)
            role = Spree::Role.find_by(name: 'front_desk')
            user.spree_roles << role
            if user.save
              user.generate_spree_api_key!
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(user.errors.full_messages[0], 403)
            end
          end

          def create_bulk_sub_client # create fd users in bulk using csv
            authorize! :create, Spree::User
            csv_data = CSV.read(params[:file].path, headers: true)
            error_message = ""
            Spree::User.transaction do
              csv_data.each do |row|
                next if row["Name"].blank? && row["Email"].blank? && row["Role"].blank?
                user = current_client.users.new(name: row["Name"], email: row["Email"], password: row["Password"], is_v2_flow_enabled: row["V2 flow"] || false, is_two_fa_enabled: row["Enable 2FA"] || false, is_enabled: row["Enable Access"] || false , state: "completed")
                error_message =  user.validate_user(csv_data.headers, row["Role"])
                error_message = "Forbidden Entity" if forbidden_tag_exist? row.to_s
                break if error_message.present?
                user.spree_roles << Spree::Role.find_by_name(:front_desk)
                unless user.save
                  error_message = "Failed to save #{user.name}: #{user.errors.full_messages.join(', ')}"
                  raise ActiveRecord::Rollback
                end
                user.generate_spree_api_key!
              end
            end
            render json: { error: error_message }, status: :unprocessable_entity if error_message.present?
          end

          def import_sub_client # create fd/sub-client users in bulk using csv
            authorize! :import_creation, Spree::User
            error_message = Spree::CreateBulkUser.new(params[:file], current_client, spree_current_user).call
            if error_message.present?
              render json: { error: error_message }, status: :unprocessable_entity
            else
              render json: { success: true }, status: :ok
            end
          end

          def export_users
            users = current_client.users.joins(:spree_roles).where(spree_roles: {name: 'front_desk'})
            data = users.map do |user|
              {
                name: user.name,
                email: user.email,
                role: user.spree_roles.last&.name,
                is_v2_flow_enabled: user.is_v2_flow_enabled,
                show_full_card_number: user.show_full_card_number,
                is_two_fa_enabled: user.is_two_fa_enabled,
                is_enabled: user.is_enabled,
              }
            end
            render json: data
          end

          def export_client_users
            users = current_client.users.accessible_by(current_ability, :index).joins(:spree_roles).where(spree_roles: {name: ['front_desk', 'sub_client']})
            data = users.map do |user|
              user_hash = {
                name: user.name,
                email: user.email,
                role: user.spree_roles.last&.name,
                is_v2_flow_enabled: user.is_v2_flow_enabled,
                show_full_card_number: user.show_full_card_number,
                is_two_fa_enabled: user.is_two_fa_enabled,
                is_enabled: user.is_enabled,
                persona_type: user.persona_type
              }
              user_hash[:can_manage_sub_user] = user.can_manage_sub_user if @spree_current_user.has_spree_role?(:client.to_s)
              user_hash
            end
            render json: data
          end
          
          def update
            authorize! :update, @user
            if @user.update(user_params)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@user).error)
            end
          end

          def is_guest_exist
            email = params[:email]
            store_id = params[:store_id]
            if email.present? and store_id.present?
              if Spree::User.find_by(store_id: store_id, email: email).present?
                render_serialized_payload { {result: true} }
              else
                render_serialized_payload { {result: false} }
              end
            end
          end

          def is_new_user
            email = params[:email]

            render_serialized_payload { { error: "Email can not be blank", result: false } } and
              return unless email.present?

            if Spree::User.without_role("customer", email).present?
              render_serialized_payload { { error: "Email has already been taken", result: false, email_available: false } }
            else
              render_serialized_payload { {result: true, email_available: true} }
            end
          end

          def mailchimp_subscription
            @user = Spree::User.find_by(email: params[:email], store_id: spree_current_store.id)
            if @user.present?
              @user.update_column(:enabled_marketing, params[:enabled_marketing]) if params.has_key?(:enabled_marketing)
              @user.update_column(:news_letter, params[:news_letter]) if params.has_key?(:news_letter)
            end
            @user = Spree::User.new(email: params[:email]) unless @user

            @user.subscription_status = if params.dig(:enabled_marketing) || params.dig(:news_letter)
              "subscribe"
            else "unsubscribe" end

            result = {}
            result[:message] = if @user.blank?
              "#{params[:email]} not present"
            elsif spree_current_store.mailchimp_setting.blank?
              @user.update(news_letter: false)
              "Mailchimp Setting not found"
            else
              spree_current_store.mailchimp_subscription(@user)[:message]
            end

            render json: { body: result }, status: 200
          end

          def merge_cart
            render json: { token: associate_cart_with_user }, status: 200
          end

          def cart
            order = spree_current_user.incomplete_order(spree_current_store)
            render json: { token: order&.token }, status: 200
          end

          def profile
            render_serialized_payload { serialize_resource(spree_current_user) }
          end

          def update_user
            if @spree_current_user.update(user_params)
              spree_current_store.mailchimp_subscription(@spree_current_user) if spree_current_store&.mailchimp_setting&.present?
              render_serialized_payload { serialize_resource(@spree_current_user) }
            else
              render_error_payload(failure(@spree_current_user).error)
            end
          end

          def user_account
            render_serialized_payload { serialize_resource(@spree_current_user) }
          end

          def search_bar_taxons
            taxons = current_client.taxons.not_vendor.select('id, name, permalink')
            render json: taxons, status: 200
          end

          def destroy
            authorize! :destroy, @user
            if @user.destroy
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(failure(@user).error)
            end
          end

          def givex_balance
            options = { card_number: params[:card_number].to_s, card_pin: params[:card_pin].to_s }

            reslut = Spree::GivexBalance.call(options: options, store: spree_current_store)
            render json: reslut.value.to_json, status: 200
          end

          def send_otp_email
            if (@user.is_two_fa_enabled && @user.is_enabled?) || (@user.is_iframe_user && !@user.verified)
              if @user.valid_password?(params[:password])
                if @user.is_iframe_user && !@user.verified
                  @user.generate_otp
                  SesEmailsDataWorker.perform_async(@user.id, "iframe_otp_verification")
                else
                  Spree::GeneralMailer.send_otp(@user).deliver_now#deliver_later
                end
                render json: { one_time_password: true, otp_required: true, iframe_signup_pending: @user.is_iframe_user && @user.state.eql?("unverified") }, status: 200
              else
                render_error_payload("Incorrect username, password or unauthorized user. Please try again, reset your password or contact admin")
              end
            else
              render json: { otp_required: false }, status: 200
            end
          end

          def verify_otp
            if @user&.active_otp&.verify(params[:otp_code])
              begin
                ActiveRecord::Base.transaction do
                  @user.active_otp.update!(verified: true)
                  @user.create_iframe_data if @user.is_iframe_user && !@user.verified
                end
                render json: { verified: true }, status: 200
              rescue => e
                render_error_payload(e.message)
              end
            else
              render_error_payload("Invalid Pin")
            end
          end

          def scheduled_reports
            if current_client.present?
              render json: { scheduled_reports: current_client.scheduled_reports }, status: 200
            else
              render_error_payload("You are not authorized to access this page")
            end
          end

          def email_for_customer_support
            email_data = {from: "zain@techsembly.com", template: "send_gift_card", template_data:{gift_card_number: params[:gift_card_number], gift_card_pin: params[:gift_card_pin] }, to: params[:recipient_email]}
            result = SnsNotification.new(email_data, params[:message], ENV['SNS_TOPIC_ARN']).publish
            result ? render_serialized_payload { success({ success: true }) } : (render json: { error: 'Failed to Send Email' }, status: :unprocessable_entity)
          end

          def get_user_roles
            render_error_payload("You need to sigin") and return unless spree_current_user

            cache_value = Rails.cache.read(params[:access_token].to_s)
            return render json: { role: cache_value, is_iframe_user: spree_current_user.is_iframe_user}, status: 200 if cache_value

            roles = spree_current_user.spree_roles.map(&:name)
            Rails.cache.write(params[:access_token].to_s,roles,expires_in: 1.hour)
            render json: { is_iframe_user: spree_current_user.is_iframe_user, role: roles}, status: 200

          end

          def service_login_users
            render json: { service_login_users: Spree::ServiceLoginUser.active_service_login_users.select('spree_users.id,spree_users.name')}, status: 200
          end

          private

          def set_user
            # in case of fufilment users current_client doesn't exit
            @user = current_client ? current_client.users.find_by('spree_users.id = ?', params[:id]) : Spree::User.accessible_by(current_ability, :index).find_by('spree_users.id = ?', params[:id])
            return render json: {error: "User not found"}, status: 403 unless @user
          end

          def otp_user
            @user = Spree::User.joins(:spree_roles).where.not(spree_roles: {name: "customer"}).where(email: params[:username].try(:downcase)).first
            render_error_payload("Incorrect username, password or unauthorized user. Please try again, reset your password or contact admin") if @user.blank?
          end

          def serialize_resource(resource)
            Spree::V2::Storefront::UserSerializer.new(
              resource,
              params: { store_id: spree_current_store&.id },
              include: resource_includes,
              sparse_fields: sparse_fields
            ).serializable_hash
          end

          def serialize_collection(collection)
            Spree::V2::Storefront::SubClientSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def user_params
            params[:user].delete(:can_manage_sub_user) unless spree_current_user&.has_spree_role?("client")
            params.require(:user).permit(:service_login_user_id, :enabled_marketing, :name, :email, :password, :password_confirmation, :user_report_password, :news_letter, :state, :is_two_fa_enabled, :is_v2_flow_enabled,:is_enabled, :show_full_card_number, :persona_type, :can_manage_sub_user, allow_store_ids: [], allow_campaign_ids: [], :menu_item_users_attributes=> [:id, :menu_item_id, :user_id, :visible, :_destroy ])
          end

          def associate_cart_with_user
            @user ||= spree_current_user
            order_token = params[:user][:order_token] if params[:user] && params[:user][:order_token]
            @order = Spree::Order.find_by(token: order_token)
            incomplete_order = (@user.orders.incomplete.where(store: spree_current_store) - [@order]).last
            # @order.associate_user!(@user) if incomplete_order.blank? && @order && @order.user.blank?
            # incomplete_order && @order && incomplete_order.merge!(@order)
            # incomplete_order.present? ? incomplete_order.token : order_token
            @order.associate_user!(@user) if @order && @order.user.blank?
            if incomplete_order.present?
              incomplete_order.line_items.destroy_all if params[:buy_now_button].present? && params[:buy_now_button]
            end
            incomplete_order && @order && @order.merge!(incomplete_order)
            return order_token if @order.present?
            incomplete_order.try(:token)
          end
        end
      end
    end
  end
end
