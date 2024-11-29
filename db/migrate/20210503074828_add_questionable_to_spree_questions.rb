class AddQuestionableToSpreeQuestions < ActiveRecord::Migration[5.2]
  def change
    add_reference :spree_questions, :questionable, polymorphic: true
  end
end
