class AddPaymentRefundReasonToSpreeRefunds < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_refunds, :payment_refund_type, :integer, default: 0
  end
end
