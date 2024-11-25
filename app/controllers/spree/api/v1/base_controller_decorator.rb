module Spree
  module Api
    module V1
      module BaseControllerDecorator

        protected
        def spree_current_user
          return nil unless doorkeeper_token
          return @spree_current_user if @spree_current_user

          doorkeeper_authorize!

          @spree_current_user ||= doorkeeper_token.resource_owner
        end

        alias try_spree_current_user spree_current_user

      end
    end
  end
end

Spree::Api::V1::BaseController.prepend Spree::Api::V1::BaseControllerDecorator
Spree::Api::V1::BaseController.include Spree::XssValidationConcern
