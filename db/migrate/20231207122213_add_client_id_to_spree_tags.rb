class AddClientIdToSpreeTags < ActiveRecord::Migration[6.0]
  def change
    add_column ActsAsTaggableOn.tags_table, :client_id, :integer
  end
end
