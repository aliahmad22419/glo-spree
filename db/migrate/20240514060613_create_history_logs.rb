class CreateHistoryLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :history_logs do |t|
      t.string :kind
      t.text :history_notes
      t.string :creator_email
      t.string :platform
      t.json :meta
      t.references :loggable, polymorphic: true, index: true
      t.references :creator, index: true, foreign_key: { to_table: :spree_users }

      t.timestamps
    end
  end
end