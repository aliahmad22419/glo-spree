class AddGoogleSiteVerificationTagToSpreeStores < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :google_site_verification_tag, :string, default: "hDqeXB6ba8wsabWbUUOuXUsu_5_tL-qU-TWGHWZM8QY"
  end
end
