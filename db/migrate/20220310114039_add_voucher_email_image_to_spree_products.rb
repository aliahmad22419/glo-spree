class AddVoucherEmailImageToSpreeProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_products, :voucher_email_image, :integer, default: 0
  end
end
