class CreateEmailTemplates < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_email_templates do |t|
      t.string :name
      t.text :subject
      t.text :email_text
      t.text :html
      t.integer :store_id
      t.string :email_type
      t.timestamps
    end
  end
end
