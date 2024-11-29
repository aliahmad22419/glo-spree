class AddPersonaTypeToSpreeUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_users, :persona_type, :string, default: "default"
  end
end
