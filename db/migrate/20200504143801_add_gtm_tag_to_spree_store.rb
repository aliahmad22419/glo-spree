class AddGtmTagToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :custom_css, :text, default: ""
    add_column :spree_stores, :gtm_tags, :text, array: true, default: "{}"
  end
end
