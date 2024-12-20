# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# Note: If a preference is set here it will be stored within the cache & database upon initialization.
#       Just removing an entry from this initializer will not make the preference value go away.
#       Instead you must either set a new value or remove entry, clear cache, and remove database entry.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'
Spree.config do |config|
  # Example:
  # Uncomment to stop tracking inventory levels in the application
  # config.track_inventory_levels = false
end

# Configure Spree Dependencies
#
# Note: If a dependency is set here it will NOT be stored within the cache & database upon initialization.
#       Just removing an entry from this initializer will make the dependency value go away.
#
Spree.dependencies do |dependencies|
  # Example:
  # Uncomment to change the default Service handling adding Items to Cart
  # dependencies.cart_add_item_service = 'MyNewAwesomeService'
end


Spree.user_class = "Spree::User"

Rails.application.config.after_initialize do
  # Promotions
  Rails.application.config.spree.promotions.rules << Spree::Promotion::Rules::ShipmentProductsTotal
  Rails.application.config.spree.promotions.actions << Spree::Promotion::Actions::BinCodeDiscount

  # Calculators
  Rails.application.config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::Weighted
    # --- Remove extra shipping method calculators added by spree 4.6 ---
  Rails.application.config.spree.calculators.shipping_methods.delete Spree::Calculator::Shipping::DigitalDelivery

  # Payment Methods
  Rails.application.config.spree.payment_methods << Spree::Gateway::AdyenGateway
  Rails.application.config.spree.payment_methods << Spree::Gateway::LinkPaymentGateway
end

::Money::Currency.register({
  :priority        => 1,
  :iso_code        => "MVR",
  :iso_numeric     => "978",
  :name            => "MVR",
  :symbol          => "ރ.",
  :subunit         => "Cent",
  :subunit_to_unit => 100,
  :separator       => ".",
  :delimiter       => ","
})