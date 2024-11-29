class CreateInfoProduct < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_info_products do |t|
      t.string :banner_overlay_text
      t.text :info_introduction
      t.string :heading_product_description
      t.string :video_url
      t.text :info_description
      t.string :info_price_statement
      t.string :book_experience_url
      t.references :product
      t.boolean :show_send_gift_card_button
      t.text :curated_by
      t.text :last_block

      t.timestamps
    end
  end
end
