module Spree
  module V2
    module Storefront
      class AddressSerializer < BaseSerializer
        set_type :address

        attributes :firstname, :lastname, :address1, :address2, :city, :zipcode, :phone,
                   :company, :email, :country_id, :apartment_no, :region, :district, :estate_name,
                   :estate_name, :user_id, :state_id, :phone_code

        attribute :state_code, &:state_abbr
        # attribute :state_name, &:state_name_text

        attribute :country_name do |object|
          object.country_name if object.country.present?
        end

        attribute :state_name do |object|
          object&.state&.name || object&.state_name
        end

        attribute :country_iso3 do |object|
          object.country_iso3 if object.country.present?
        end

        attribute :country_iso do |object|
          object.country_iso if object.country.present?
        end
        
      end
    end
  end
end
