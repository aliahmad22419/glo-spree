class AddOptionsTextToSpreeLineItems < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_line_items, :option_values_text, :jsonb , :default => []
  end
end
