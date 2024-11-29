class AddAttributeToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_questions, :guest_email, :string
    add_column :spree_questions, :guest_name, :string
    add_column :spree_questions, :customer_id, :integer
  end
end
