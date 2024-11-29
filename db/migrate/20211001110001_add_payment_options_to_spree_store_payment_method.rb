class AddPaymentOptionsToSpreeStorePaymentMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_store_payment_methods, :payment_option, :string
    add_column :spree_store_payment_methods, :payment_option_display, :string
  end
end
