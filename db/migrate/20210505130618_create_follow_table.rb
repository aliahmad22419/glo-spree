class CreateFollowTable < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_follows do |t|
      t.integer :follower_id
      t.integer :followee_id
      t.string :name
      t.string :email
      t.text :details
      t.string :status, default: "pending"
      t.timestamps
    end
  end
end
