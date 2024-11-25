module MixPanel
  extend ActiveSupport::Concern
  include ActionController::Cookies

  included do
    before_action :set_params, only: [:home, :sub_categories, :cart, :add_item, :update, :checkout, :complete, :remove_line_item]
  end

# set params functions used to set action_name and store_id
  def set_params
    action_name = params[:action]
    if  params[:controller] == "storefront"
      store = current_store
    else
      store = spree_current_store
    end
    if store && store.preferred_enable_mixpanel
      # set action_name
      case action_name
      when "update"
        if params.dig(:order, :ship_address_attributes)
          action_description = "Shipping address"
        elsif params.dig(:order, :shipments_attributes)
          action_description = "Shipment"
        elsif params.dig(:order, :payments_attributes)
          action_description = "Payment and Complete"
        end
      when "add_item"
        action_description = "Add to Cart"
      when "complete"
        action_description = "Order Completed"
      when "checkout"
        action_description = "Checkout"
      when "cart"
        action_description = "Cart"
      when "home"
        action_description = "Home"
      when "remove_line_item"
        action_description = "Remove from cart"
      when "sub_categories"
        action_description = "Product Detail" if  Spree::Product.find_by(slug: params.dig(:id))
      end

      MixpanelWorker.perform_async(store.id,action_description,request.cookies, request.remote_ip) if action_description
    end
  end
end
