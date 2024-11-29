class AddRecaptchaToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :recaptcha_key, :string, default: ""
  end
end
