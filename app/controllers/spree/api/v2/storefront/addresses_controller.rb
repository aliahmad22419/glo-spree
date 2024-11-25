module Spree
  module Api
    module V2
      module Storefront
        class AddressesController < ::Spree::Api::V2::BaseController
          before_action :set_country_by_iso, only: [:update, :create]
          before_action :require_spree_current_user
          before_action :set_address, only: [:update, :show, :destroy]

          def index
            addresses = @spree_current_user.addresses.where(store_id: spree_current_store.id)
            render_serialized_payload { serialize_collection(addresses) }
          end

          def show
            render_serialized_payload { serialize_resource(@address) }
          end

          def create
            address = @spree_current_user.addresses.build(address_params_with_store_and_country)
            if address.save
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(address).error)
            end
          end

          def update
            if @address.update(address_params_with_store_and_country)
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@address).error)
            end
          end

          def destroy
            if @address.destroy
              render_serialized_payload { success({success: true}).value  }
            else
              render_error_payload(failure(@address).error)
            end
          end

          private
            def set_country_by_iso
              @country = Country.find_by(iso: params[:address][:country_iso])
            end

            def address_params_with_store_and_country
              address_params.merge({store_id: spree_current_store.id, country_id: @country.id})
            end

            def serialize_resource(resource)
              Spree::V2::Storefront::AddressSerializer.new(resource).serializable_hash
            end

            def serialize_collection(collection)
              Spree::V2::Storefront::AddressSerializer.new(collection).serializable_hash
            end

            def set_address
              @address = @spree_current_user.addresses.find_by('spree_addresses.id = ?', params[:id])
              return render json: { error: "Resource you are looking for not found" }, status: :not_found unless @address
            end

            def address_params
              params[:address].permit(:address,
                                      :firstname,
                                      :lastname,
                                      :address1,
                                      :address2,
                                      :city,
                                      :state_id,
                                      :zipcode,
                                      :country_id,
                                      :phone,
                                      :state_name,
                                      :region,
                                      :district,
                                      :estate_name,
                                      :apartment_no
                                     )
            end
        end
      end
    end
  end
end
