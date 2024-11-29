class CreateSpreeAdyenCheckouts < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_adyen_checkouts do |t|
      t.string :number
      t.string :month
      t.string :year
      t.string :cc_type
      t.string :name
      t.string :gateway_payment_profile_id
      t.string :gateway_customer_profile_id
      t.string :payment_method_id
      t.string :user_id
      t.string :verification_value
      t.string :status
      t.string :psp_reference
      t.json :three_ds_action
      t.json :card_details

      t.timestamps
    end
  end
end
