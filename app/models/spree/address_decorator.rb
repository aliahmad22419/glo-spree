module Spree
  module AddressDecorator
    def self.prepended(base)
      base.clear_validators!
    end
    # ADDRESS_FIELDS = %w(firstname lastname company address1 address2 city state zipcode country phone apartment_no estate_name region district)

    # with_options presence: true do
    #   validates :firstname, :lastname, :address1, :country
    #   validates :city, if: :require_state_or_region?
    #   validates :region, :district, if: :require_region?
    #   validates :zipcode, if: :require_zipcode?
    #   validates :phone, if: :require_phone?
    # end

    # validate :state_validate, :postal_code_validate

    # def require_zipcode?
    #   country ? country.zipcode_required? : true
    # end

    # def require_state_or_region?
    #   country && (country.region_required || country.states_required)
    # end

    # def require_region?
    #   country && country.region_required
    # end

    def full_address
    [address1, address2 , city, region, district, country.name, zipcode].compact.join(', ')
    end

    def get_full_address
      [address1, address2, apartment_no, city, (state.present?? state&.name : state_name), region, district, zipcode, phone, country&.name].compact.join(', ')
    end

    def full_username
      "#{firstname} #{lastname}"
    end

    def destroy
      super
    end
  end
end

Spree::Address.prepend Spree::AddressDecorator
