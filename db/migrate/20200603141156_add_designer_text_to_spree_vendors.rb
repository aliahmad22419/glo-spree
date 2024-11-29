class AddDesignerTextToSpreeVendors < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_vendors, :designer_text, :text, default: ""
  end
end
