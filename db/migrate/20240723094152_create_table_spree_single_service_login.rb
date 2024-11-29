class CreateTableSpreeSingleServiceLogin < ActiveRecord::Migration[6.1]
  def change
    create_table :spree_clients_service_login do |t|
      t.references :service_login_sub_admin, null: false, foreign_key: { to_table: :spree_users }
      t.references :client, null: false, foreign_key:  { to_table: :spree_clients }
      t.timestamps
    end
  end
end
