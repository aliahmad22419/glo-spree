class AddColumnsAndDataToSpreePaymentMethodsStores < ActiveRecord::Migration[6.1]
  def up
    # Add columns to spree_payment_methods_stores
    # add_column :spree_payment_methods_stores, :created_at, :datetime, default: DateTime.now, null: false
    # add_column :spree_payment_methods_stores, :updated_at, :datetime, default: DateTime.now, null: false
    # add_column :spree_payment_methods_stores, :payment_option, :string
    # add_column :spree_payment_methods_stores, :payment_option_display, :string
    # add_column :spree_payment_methods_stores, :apple_pay_domains, :integer, default: 1
    # add_column :spree_payment_methods_stores, :preferences, :text
    # remove_index :spree_payment_methods_stores, name: "payment_method_id_store_id_unique_index"

    # execute <<-SQL
    #   INSERT INTO spree_payment_methods_stores (payment_method_id, store_id, created_at, updated_at, payment_option, payment_option_display, apple_pay_domains, preferences)
    #   SELECT payment_method_id, store_id, created_at, updated_at, payment_option, payment_option_display, apple_pay_domains, preferences
    #   FROM spree_store_payment_methods;
    # SQL
  end

  def down
    # Remove columns from spree_payment_methods_stores
    # remove_column :spree_payment_methods_stores, :created_at
    # remove_column :spree_payment_methods_stores, :updated_at
    # remove_column :spree_payment_methods_stores, :payment_option
    # remove_column :spree_payment_methods_stores, :payment_option_display
    # remove_column :spree_payment_methods_stores, :apple_pay_domains
    # remove_column :spree_payment_methods_stores, :preferences
    # add_index :spree_payment_methods_stores, ["payment_method_id", "store_id"], name: "payment_method_id_store_id_unique_index", unique: true
  end
end
