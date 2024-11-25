module Spree
  module Api
    module V2
      module Storefront
        class ClientsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:product_csv, :create, :iframe_signup]
          before_action :check_permissions
          before_action :check_domain_availability, only: [:create]

          def upload_json
            @json = current_client.json_files.find_or_initialize_by(source: params[:source])
            @json.content.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)

            if @json.save
              send_data @json.content.blob.download, filename: @json.content.filename.to_s, content_type: 'application/json'
            else
              render json: { error: @json.errors.full_messages[0] }, status: :unprocessable_entity
            end
          end

          def update
            if current_client.update(client_params.except(:preferences))
              current_client.update_preferences(client_params[:preferences])
              spree_current_user.update(user_params) if user_params && user_params[:password]
              render_serialized_payload { serialize_resource(current_client)}
            else
              render_error_payload(failure(current_client).error)
            end
          end

          def create_ts_client
            response = TsCurate::TsClientService.new(spree_current_user, ts_client_params).ts_user_client
            
            if response.success
              render_serialized_payload { success({ success: true }).value }
            else
              render json: { error: response.error }, status: :unprocessable_entity
            end
          end

          def product_csv
            if params[:id].present?
              store = Spree::Store.where(name: params[:id])&.first
              if store.present?
                send_data Spree::Client.to_csv(store), filename: "#{store.name}-products-#{Date.today}.csv"
              else
                render :nothing => true, :status => 204
              end
            end
          end

          def create
            user, @client = Spree::Client.create_user_data(params)
            if @client.present?
              @client.create_data(params[:store_name], params[:preferences])
              render_serialized_payload { success(@client).value }
            else
              render_error_payload(failure(user).error)
            end
          end

          def iframe_signup
            ActiveRecord::Base.transaction do
              user, @client = Spree::Client.create_user_data(params, true, true)
              if @client.present?
                user.generate_otp
                Iframe::Onboarding.new().create_store(params[:store_name], @client.id)
                SesEmailsDataWorker.new().perform(user&.id, "iframe_otp_verification")
                render_serialized_payload { success(@client).value }
              else
                render_error_payload(failure(user).error)
              end
            end
          end

          def sign_up
            if params[:client_address].present?
              update_client_address
              current_client.save
              render_serialized_payload { serialize_resource(current_client) }
            end
            if  params[:client].present?
              if current_client.update(client_params)
                  render_serialized_payload { serialize_resource(current_client) }
              else
                result = failure(current_client)
                render_error_payload(result.error)
              end
            end
          end

          def iframe_business_details
            if params[:client_address].present?
              update_client_address
              update_stripe_credentials(params, current_client&.client_address&.country&.name) if params[:store_id].present?
              render_serialized_payload { serialize_resource(current_client) }
            end
            if  params[:client].present?
              if current_client.update(client_params)
                  render_serialized_payload { serialize_resource(current_client) }
              else
                result = failure(current_client)
                render_error_payload(result.error)
              end
            end
          end

          def is_new_company
            if params[:company_name].present?
              company_exists =  Spree::Address.exists?(company:  params[:company_name])
              client_address = spree_current_user.client.client_address
              if company_exists && client_address.present? && client_address.company == params[:company_name]
                company_exists = false
              end
              render_serialized_payload { {result: company_exists} }
            end
          end

          def get_client
            render_serialized_payload { serialize_resource(current_client) }
          end

          def reporting_exchange_rates
            data = {
              'exchange_rates' => current_client&.reporting_currency_exchange_rates,
              'reporting_currency' => current_client&.reporting_currency
            }
            render_serialized_payload { success(data).value }
          end

          private

          def serialize_resource(resource)
            Spree::V2::Storefront::ClientSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def update_stripe_credentials(params, country_name)
            current_client.update_columns(name: params[:client_address][:company])
            store = Spree::Store.find_by_id(params[:store_id])
            if store
              sg_stripe = ["Singapore", "Thailand", "Japan", "Australia"].include?(country_name)
              payment_method_preferences = {
                publishable_key: sg_stripe ? ENV['SG_STRIPE_PUBLISHABLE_KEY'] : ENV['ROW_STRIPE_PUBLISHABLE_KEY'],
                client_key: sg_stripe ? ENV['SG_STRIPE_CLIENT_KEY'] : ENV['ROW_STRIPE_CLIENT_KEY'],
                secret_key: sg_stripe ? ENV['SG_STRIPE_SECRET_KEY'] : ENV['ROW_STRIPE_SECRET_KEY']
                }
              store&.client&.payment_methods.each{|payment_method| payment_method.update_preferences(payment_method_preferences) if !payment_method[:preferences][:test_mode]}
            end
          end

          def update_client_address
            params[:client_address].permit!
            client_address = current_client.client_address
            client_address = current_client.build_client_address if client_address.blank?
            client_address.attributes = params[:client_address]
            client_address.save(validate: false)
            current_client.client_address_id = client_address.id
            current_client.save
          end

          def client_params
            params.require(:client).permit(:from_phone_number,:show_gift_card_number,:show_all_gift_card_digits, :sales_report_password, :customer_support_email, :reporting_currency, :already_selling, :current_revenue, :type_of_industry, :selling_platform, :multi_vendor_store, :business_name, :skill_level, :product_type, :auto_approve_products, :zone_based_stores, :name, :number_of_images, :allow_brand_follow, :timezone, :reporting_from_email_address, :act_as_merchant, embed_widgets_attributes: [:id, :site_domain, :_destroy], supported_currencies: [], product_validations: [], preferences: {})
          end

          def user_params
            params.permit(:password)
          end

          def ts_client_params
            params.require(:ts_client).permit(:name, :email, :password, :password_confirmation, :ts_url, :origin, :enable_request_id)
          end

          def check_domain_availability
            render_error_payload("Store name can not be blank.", 422) and return unless params[:store_name].present?
            
            domain = params[:store_name].parameterize + ".techsembly.com"
            render_error_payload("Storename has already been taken.", 422) and return unless Spree::Store.domain_available?(domain)
          end
        end
      end
    end
  end
end
