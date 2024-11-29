class AddReviewAttributesToSpreeStore < ActiveRecord::Migration[5.2]
  def change
    add_column :spree_stores, :enable_review_io, :boolean, default: false
    add_column :spree_stores, :reviews_io_api_key, :string, default: ""
    add_column :spree_stores, :reviews_io_store_id, :string, default: ""
    add_column :spree_stores, :reviews_io_bcc_email, :string
  end
end
