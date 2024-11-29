class AddPaymentMethodTypesToSpreePaymentMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_payment_methods, :payment_options, :text, array: true, default: "{}"
  end
end
