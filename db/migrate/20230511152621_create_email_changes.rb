class CreateEmailChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :email_changes do |t|
      t.integer :user_id
      t.string :previous_email
      t.string :next_email
      t.text :note
      t.references :updatable, polymorphic: true, index: true

      t.timestamps
    end
  end
end
