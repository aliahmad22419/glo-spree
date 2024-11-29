class CreateLogsOrderErrorLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :order_error_logs do |t|
      t.integer :error_type, null: false
      t.integer :status, null: false, default: 0
      t.integer :attempts, null: false, default: 0
      t.string :message, null: false
      t.json :meta
      t.references :order, index: true, foreign_key: { to_table: :spree_orders }
      t.references :line_item, index: true, foreign_key: { to_table: :spree_line_items }

      t.timestamps
    end
  end
end
