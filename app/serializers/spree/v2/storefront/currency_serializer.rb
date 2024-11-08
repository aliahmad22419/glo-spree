module Spree
  module V2
    module Storefront
      class CurrencySerializer < BaseSerializer
        set_type :currency

        attributes :name, :value

        attribute :exchange_rates do |object|
          Spree::V2::Storefront::ExchangeRateSerializer.new(object.exchange_rates.order(:name)).serializable_hash
        end

        attribute :markups do |object|
          Spree::V2::Storefront::MarkupSerializer.new(object.markups.order(:name)).serializable_hash
        end

      end
    end
  end
end
