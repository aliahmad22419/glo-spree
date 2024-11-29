class CreateSpreeSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_subscriptions do |t|
      t.string :email
      t.string :status
      t.string :list_id
      t.string :subscriber_id
      t.integer :user_id
      t.references :store

      t.timestamps
    end
  end
end
