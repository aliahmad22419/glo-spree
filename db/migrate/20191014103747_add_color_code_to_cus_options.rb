class AddColorCodeToCusOptions < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_customization_options, :color_code, :string
  end
end
