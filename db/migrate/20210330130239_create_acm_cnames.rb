class CreateAcmCnames < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_acm_cnames do |t|
      t.string :name
      t.string :c_type
      t.string :value
      t.string :domain_name
      t.string :validation_method
      t.string :validation_status
      t.integer :store_id
    end
  end
end
