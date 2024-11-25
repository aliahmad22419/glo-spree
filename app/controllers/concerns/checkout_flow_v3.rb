module CheckoutFlowV3
  extend ActiveSupport::Concern
  include ActionController::Cookies

  included do
    before_action :delete_v3_address_for_other_flows, only: [:show]
    before_action :set_guest_email, only: [:show], if: -> { spree_current_store.checkout_v3? }
    before_action :set_shipping_address_for_v3_flow, only: [:show], if: :is_not_iframe_v3_flow
  end

  def is_not_iframe_v3_flow
    spree_current_store.preferred_store_type != 'iframe' && spree_current_store.checkout_v3? && !spree_current_store.enable_v3_billing?
  end

  def set_shipping_address_for_v3_flow
    spree_current_order&.update_column(:user_id, nil)
    cookies.delete :"#{spree_current_store.id}_access_token"
    if spree_current_order.digital?
      address = spree_current_order.build_ship_address(spree_current_store&.v3_flow_address&.attributes&.except("id"))
      address.is_v3_flow_address = true
      address.save
      address = spree_current_order.build_bill_address(spree_current_store&.v3_flow_address&.attributes&.except("id"))
      address.is_v3_flow_address = true
      address.save
      spree_current_order.state = 'address'
      spree_current_order.save!
    end
  end

  def delete_v3_address_for_other_flows
    spree_current_order&.shipping_address&.delete if spree_current_order&.shipping_address&.is_v3_flow_address
    spree_current_order&.billing_address&.delete if spree_current_order&.billing_address&.is_v3_flow_address
  end

  def set_guest_email
    return unless spree_current_order.digital?
    spree_current_order.update_column(:email, cookies["#{spree_current_store.id}_guest_email"])
  end

end

