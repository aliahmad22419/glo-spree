class CreateSpreeAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_answers do |t|
      t.string :title
      t.integer :question_id
      t.timestamps null: false
    end
  end
end
