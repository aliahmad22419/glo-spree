class AddSkillLevelInClient < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_clients, :business_name, :string
    add_column :spree_clients, :skill_level, :string
    add_column :spree_clients, :product_type, :string
  end
end
