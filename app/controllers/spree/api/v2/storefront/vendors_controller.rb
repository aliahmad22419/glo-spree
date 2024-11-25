module Spree
  module Api
    module V2
      module Storefront
        class VendorsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:get_vendor, :vendor_account], :if => Proc.new{ params[:access_token] }
          before_action :set_vendor, only: [:adyen_account, :show, :update]
          before_action :set_adyen_account, only: [:adyen_account]
          before_action :authorized_client_sub_client, only: [:create, :sign_up]

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            if params[:q].present? && params[:q][:all_data]
              params[:fields] = params[:q][:fields]
              vendors = current_client.vendors
              render_serialized_payload { serialize_collection_without_pagination(vendors) }
            else
              vendors = Spree::Vendor.not_master.accessible_by(current_ability, :index).ransack(params[:q]).result
              vendors = collection_paginator.new(vendors, params).call
              render_serialized_payload { serialize_collection(vendors) }
            end
          end

          def show
            render_serialized_payload { serialize_resource(@vendor) }
          end

          def get_vendor
            vendor = Spree::Vendor.find_by(slug: params[:id])
            render_serialized_payload { serialize_resource(vendor) }
          end

          def profile
            if @spree_current_user.present? && (@spree_current_user.user_with_role("client") || @spree_current_user.user_with_role("sub_client"))
              vendor = current_client.master_vendor
            else
              vendor = @spree_current_user.vendors.first
            end
            render_serialized_payload { serialize_resource(vendor) }
          end

          def update
            render_error_payload("Vendors not found",404) and return unless @vendor
            authorize! :update, @vendor
            params[:shipping_address].permit!
            params[:billing_address].permit!
            params[:user].permit!
            shiping_address = @vendor.shipping_address
            shiping_address = @vendor.build_ship_address if shiping_address.blank?
            billing_address = @vendor.billing_address
            billing_address = @vendor.build_bill_address if billing_address.blank?
            user = @vendor&.users&.first
            @vendor.attributes = vendor_params
            if @vendor.save
              shiping_address.attributes = params[:shipping_address]
              shiping_address.save(validate: false)
              billing_address.attributes = params[:billing_address]
              billing_address.save(validate: false)
              user.update(params[:user]) if user.present?
              render_serialized_payload { serialize_resource(@vendor) }
            else
              result = failure(@vendor)
              render_error_payload(result.error)
            end
          end

          def create
            Vendor.transaction do
              vendor = current_client.vendors.new(vendor_params)
              params[:shipping_address].permit!
              params[:billing_address].permit!
              params[:user].permit!
              shiping_address = Spree::Address.new(params[:shipping_address])
              billing_address = Spree::Address.new(params[:billing_address])

              user = Spree.user_class.new(params[:user])
              user.spree_role_ids = Spree::Role.find_by_name("vendor").id

              if user.valid?
                if vendor.valid?
                  user.save
                  vendor.save
                  vendor.users << user
                  shiping_address.save(validate: false)
                  billing_address.save(validate: false)
                  vendor.shipping_address = shiping_address
                  vendor.billing_address = billing_address
                  vendor.save
                  render_serialized_payload { serialize_resource(vendor) }
                else
                  result = failure(vendor)
                  render_error_payload(result.error)
                end
              else
                render_error_payload(failure(user).error)
              end


            end
          end

          def sign_up
            Vendor.transaction do
              vendor = current_client.vendors.new(vendor_params)
              user = Spree.user_class.new(email: params[:vendor][:email], password: '12345678!')
              user.spree_role_ids = Spree::Role.find_by_name("vendor").id
              store_name = current_client&.stores&.first&.name
              if vendor.valid? && user.valid?
                user.save
                vendor.users << user
                vendor.save
                Spree::SES::Mailer.invite_vendor(current_client.email, user.email, @spree_current_user.email, store_name)
                render_serialized_payload { success({success: true}).value }
              else
                render_error_payload(failure(vendor).error)
              end
            end
          end

          def vendor_account
            user = Spree::User.find_by(email: params[:email])
            if params[:email].present? && user.present? && (user.spree_roles.map(&:name).include?"vendor")
              vendor = user.vendors.first
              vendor.name = params[:name]
              user.password = params[:password]
              if user.valid?
                if vendor.valid?
                  user.save
                  vendor.save
                  render_serialized_payload { success({success: true}).value }
                else
                  render_error_payload(failure(vendor).error)
                end
              else
                render_error_payload(failure(user).error)
              end

            else
              payload = {
                  error: "No such user; check the submitted email address",
                  status: 403
              }
              render :json => payload, :status => :bad_request
            end
          end

          def update_billing_address
            params.permit!
            vendor = @spree_current_user.vendors.first
            billing_address = vendor.build_bill_address
            billing_address.attributes = params[:address]
            if billing_address.save(validate: false)
              vendor.bill_address_id = billing_address.id
              vendor.save
              render_serialized_payload { success({success: true}).value }
            else
              result = failure(billing_address)
              render_error_payload(result.error)
            end
          end

          # def destroy
          #   render_error_payload("Vendors not found",404) and return unless @vendor
          #   render_error_payload("Action Not Allowed, Vendor products exist", 401) and return if @vendor.products.any?
          #   if @vendor.users.first.delete
          #     @vendor.destroy
          #     render_serialized_payload { serialize_resource(@vendor) }
          #   else
          #     result = failure(@vendor)
          #     render_error_payload(result.error)
          #   end
          # end

          # def destroy_multiple
          #   vendors = current_client.vendors.where(id: JSON.parse(params[:ids]))
          #   return render json: {errors: "Vendors not found"}, status: :not_found if vendors.blank? || vendors.empty?
          #
          #   if vendors.destroy_all
          #     render_serialized_payload { success({success: true}).value }
          #   else
          #     render_error_payload(failure(vendors).error)
          #   end
          # end

          def upload_image
            img = Spree::Image.new(viewable_type: "Spree::Vendor", attachment_file_name: params[:file].original_filename)
            img.attachment.attach(io: File.open(params[:file].path), filename: params[:file].original_filename)
            if img.save
              serilizaed_image = Spree::V2::Storefront::ImageSerializer.new(img).serializable_hash
              render_serialized_payload { serilizaed_image }
            else
              render_error_payload(failure(img).error)
            end
          end

          def adyen_account
            accountUrl = if @adyen_account.persisted?
              @adyen_account.onboarding_url
            else
              @adyen_account.request_holder_account(params[:adyen_account].to_unsafe_h
                                .merge({ "accountHolderCode" => "VENDOR-1045-#{@vendor.id}" }))
              end
            if @adyen_account.errors.any?
              render_error_payload(@adyen_account.errors.full_messages[0], 403)
            else
              render json: { redirtectUrl: accountUrl }, status: 200
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
            Spree::V2::Storefront::VendorSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def serialize_collection_without_pagination(collection)
            allow_store_ids = []
            allow_store_ids = @spree_current_user&.allow_store_ids if @spree_current_user.present? && (@spree_current_user.user_with_role("sub_client") || @spree_current_user.user_with_role("vendor"))
            Spree::V2::Storefront::VendorSerializer.new(
                collection,
                {
                    fields: sparse_fields,
                    params: {
                    allow_store_ids: allow_store_ids
                  }
                }
            ).serializable_hash
          end

          def collection_options(collection)
            allow_store_ids = []
            allow_store_ids = @spree_current_user&.allow_store_ids if @spree_current_user.present? && (@spree_current_user.user_with_role("sub_client") || @spree_current_user.user_with_role("vendor"))
            {
              links: collection_links(collection),
              meta: collection_meta(collection),
              include: resource_includes,
              fields: sparse_fields,
              params: {
                    allow_store_ids: allow_store_ids
                }
            }
          end

          def serialize_resource(resource)
            allow_store_ids = []
            allow_store_ids = @spree_current_user&.allow_store_ids if @spree_current_user.present? && (@spree_current_user.user_with_role("sub_client") || @spree_current_user.user_with_role("vendor"))
            Spree::V2::Storefront::VendorSerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields,
                params: {
                    followee_user_id: @spree_current_user&.id,
                    allow_store_ids: allow_store_ids,
                    hide_client_user_id: "true",
                }
            ).serializable_hash
          end

          # this is resource_includes. We overwite this method
          # def default_resource_includes
          #   ['billing_address','shipping_address','users']
          # end

          def set_adyen_account
            @adyen_account = @vendor.adyen_account
            @adyen_account ||= @vendor.build_adyen_account
          end

          def set_vendor
            if params[:find_from_all]
              @vendor = storefront_current_client&.vendors&.friendly&.find(params[:id])
            else
              @vendor = current_client&.vendors&.friendly&.find(params[:id])
            end
            return render json: {error: "Vendor not Found"}, status: 403 unless @vendor
          end

          def vendor_params
            params.require(:vendor).permit(:external_vendor, :sales_report_password, :microsite, :name, :email, :contact_name, :enabled, :page_enabled, :phone, :vacation_mode, :vacation_start, :state, :vacation_end, :conf_contact_name, :landing_page_title, :enabled_google_analytics, :google_analytics_account_number, :description, :banner_image_id, :image_id, :landing_page_url, :additional_emails, :designer_text, :agreed_to_client_terms, :about_us,  local_store_ids: [])
          end
        end
      end
    end
  end
end
