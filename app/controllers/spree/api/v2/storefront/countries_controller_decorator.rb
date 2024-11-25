module Spree
  module Api
    module V2
      module Storefront
        module CountriesControllerDecorator
          def index
            collection = Spree::Country.all.order('name ASC')
            render_serialized_payload { serialize_collection(collection.order(name: :asc)) }
          end

          def remove_countries_with_store_name
            all_countries = JSON.parse(params[:all_countries])
            if all_countries
              collection = Spree::Country.all.includes(:states)
            else
              collection = spree_current_store&.countries.includes(:states)
            end
            render_serialized_payload { serialize_collection(collection.order(name: :asc)) }
          end

          private

          def serialize_collection(collection)
            collection_serializer.new(
              collection,
              collection_options(collection).merge(params: {include_states: true})
            ).serializable_hash
          end

        end
      end
    end
  end
end

::Spree::Api::V2::Storefront::CountriesController.prepend(Spree::Api::V2::Storefront::CountriesControllerDecorator)
