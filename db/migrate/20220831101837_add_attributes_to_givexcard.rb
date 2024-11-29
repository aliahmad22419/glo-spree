class AddAttributesToGivexcard < ActiveRecord::Migration[5.2]
  def change
    add_reference :spree_givex_cards, :store
    add_reference :spree_givex_cards, :client
    add_column :spree_givex_cards, :from_email, :string, default: ''
    add_column :spree_givex_cards, :invoice_id, :string, default: ''
    add_timestamps :spree_givex_cards, default: DateTime.now
    change_column_default :spree_givex_cards, :created_at, from: DateTime.now, to: nil
    change_column_default :spree_givex_cards, :updated_at, from: DateTime.now, to: nil
  end
end
