module Spree
  module Api
    module V2
      module Storefront
        class GeneralSettingsController < ::Spree::Api::V2::BaseController

          before_action :storefront_client_not_found, only: [:supported_currency]

          def supported_currency
            # preference = Spree::Preference.where(key: "spree/app_configuration/supported_currencies")
            # render_serialized_payload { serialize_preference_collection(preference) }
            render_serialized_payload { success({supported_currencies: storefront_current_client.supported_currencies}).value }
          end

          def categories_json
            taxons = Spree::Taxon.all
            taxon_hash = {}
            taxons.each do |t|
              taxon_hash[t.permalink] = {
                tittle: t.meta_title.present? ? t.meta_title.to_s: t.name.to_s,
                desc: t.meta_description.present? ? t.meta_description.to_s : t.description.to_s,
                keywords: t.meta_keywords.to_s
              }
            end
            render json: taxon_hash.to_json
          end

          def products_json
            products = Spree::Product.all
            products_hash = {}
            products.each do |p|
              image = p.images.where(base_image: true).first.present? ? p.images.where(base_image: true).first : p.images.first
              image_url = image.present? ? "https://glo.techsembly.com" + image.styles.last[:url] : ""
              products_hash[p.slug] = {
                tittle: p.meta_title.present? ? p.meta_title.to_s : p.name.to_s,
                desc: p.meta_description.present? ? p.meta_description.to_s : p.description.to_s,
                keywords: p.meta_keywords,
                image_url: image_url
              }
            end
            render json: products_hash.to_json
          end

          private

          def serialize_preference_collection(collection)
            Spree::V2::Storefront::PreferenceSerializer.new(collection).serializable_hash
          end

        end
      end
    end
  end
end
