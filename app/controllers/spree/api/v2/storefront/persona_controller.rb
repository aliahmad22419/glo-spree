module Spree
  module Api
    module V2
      module Storefront
        class PersonaController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user
          before_action :check_permissions

          def index
            personas = current_client.personas.order("created_at DESC")
            personas = collection_paginator.new(personas, params).call
            render_serialized_payload { serialize_collection(personas) }
          end
        
          private

          def serialize_collection(collection)
            Spree::V2::Storefront::PersonaSerializer.new(
                collection,
                collection_options(collection)
            ).serializable_hash
          end

          def persona_params
            params.require(:persona).permit(:name, :persona_code, store_ids: [], menu_item_ids: [], campaign_ids: [])
          end

        end
      end
    end
  end
end