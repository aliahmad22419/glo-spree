class CreateSpreeOtps < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_otps do |t|
      t.string :secret_key
      t.boolean :verified, default: false
      t.references :user

      t.timestamps
    end
  end
end
