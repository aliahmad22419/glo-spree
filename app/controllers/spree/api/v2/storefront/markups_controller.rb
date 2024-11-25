module Spree
  module Api
    module V2
      module Storefront
        class MarkupsController < ::Spree::Api::V2::BaseController

          before_action :require_spree_current_user
          before_action :set_vendor, only: [:index, :create]

          def index
            base_currency = @vendor.base_currency
            render_serialized_payload { serialize_resource(base_currency) }
          end

          def create
            base_currency = @vendor.base_currency
            base_currency =  @vendor.build_base_currency if base_currency.blank?
            base_currency.name = params[:base]
            base_currency.save
            markups = params[:markups]
            markups.each do |markup|
              puts markup
              update_markup = base_currency.markups.where(name: markup["name"]).first
              update_markup = base_currency.markups.new(name: markup["name"]) if update_markup.blank?
              update_markup.value = markup["value"]
              update_markup.save
            end
            render_serialized_payload { {success: true} }
          end

          private

          def serialize_resource(resource)
            Spree::V2::Storefront::CurrencySerializer.new(
                resource,
                include: resource_includes,
                sparse_fields: sparse_fields
            ).serializable_hash
          end

          def set_vendor
            @vendor = @spree_current_user.vendors.first || current_client&.master_vendor
          end

        end
      end
    end
  end
end
