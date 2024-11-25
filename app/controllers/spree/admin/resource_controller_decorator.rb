
module Spree
  module Admin
    module ResourceControllerDecorator
      protected

      def load_resource_instance
        if new_actions.include?(action)
          build_resource
        elsif params[:id]
          model_class.try(:friendly)&.exists?(params[:id]) ? find_friendly_resource : find_resource
        end
      end

      # duplicated, just to see difference without friendly_id
      def find_resource
        if parent_data.present?
          parent.send(controller_name).find(params[:id])
        else
          model_class.find(params[:id])
        end
      end

      def find_friendly_resource
        if parent_data.present?
          parent.send(controller_name).friendly.find(params[:id])
        else
          model_class.friendly.find(params[:id])
        end
      end
    end
  end
end

::Spree::Admin::ResourceController.prepend Spree::Admin::ResourceControllerDecorator if ::Spree::Admin::ResourceController.included_modules.exclude?(Spree::Admin::ResourceControllerDecorator)
