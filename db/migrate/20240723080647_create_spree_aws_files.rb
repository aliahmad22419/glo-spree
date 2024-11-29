class CreateSpreeAwsFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :spree_aws_files do |t|
      t.string :name
      t.string :url
      t.string :comment
      t.boolean :active, default: false
      t.string :file_type, default: 'text'
      t.references :client, index: true
      t.references :created_by, index: true, foreign_key: { to_table: :spree_users }
      t.timestamps
    end
  end
end
