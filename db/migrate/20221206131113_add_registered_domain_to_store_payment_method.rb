class AddRegisteredDomainToStorePaymentMethod < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_store_payment_methods, :apple_pay_domains, :integer, default: 1
  end
end
