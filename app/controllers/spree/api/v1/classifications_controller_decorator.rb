module Spree
  module Api
    module V1
      module ClassificationsControllerDecorator
        def update
          authorize! :update, Spree::Product
          authorize! :update, Spree::Taxon
          authorize! :update, Spree::Store
          classification = Spree::Classification.find_or_create_by!(
            product_id: params[:product_id],
            taxon_id: params[:taxon_id],
            store_id: params[:store_id]
          )
          # Because position we get back is 0-indexed.
          # acts_as_list is 1-indexed.
          classification.insert_at(params[:position].to_i)
          head :ok
        end

        def bulk_update
          authorize! :update, Spree::Product
          authorize! :update, Spree::Taxon
          authorize! :update, Spree::Store

          product_ids = JSON.parse(params[:product_ids])

          product_ids.each do |product_id|
            classification = Spree::Classification.find_or_create_by!(
                product_id: product_id,
                taxon_id: params[:taxon_id],
                store_id: params[:store_id]
            )
            # Because position we get back is 0-indexed.
            # acts_as_list is 1-indexed.
            classification.insert_at(params[:position].to_i)
          end

          head :ok
        end
      end
    end
  end
end

::Spree::Api::V1::ClassificationsController.prepend Spree::Api::V1::ClassificationsControllerDecorator if ::Spree::Api::V1::ClassificationsController.included_modules.exclude?(Spree::Api::V1::ClassificationsControllerDecorator)
