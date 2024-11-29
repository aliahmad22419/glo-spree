class AddRefundNotesToSpreeLineItems < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_line_items, :refund_notes, :text
  end
end
