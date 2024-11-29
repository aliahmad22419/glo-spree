class AddHcaptchaKeyToSpreeStores < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_stores, :hcaptcha_key, :string, default: ''
  end
end
