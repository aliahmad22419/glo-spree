# client.taxons.where("lower(name) <> ?", "categories").destroy_all
# client.taxonomies.where("lower(name) <> ?", "categories").destroy_all
def import_categories client, file
  results = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| results << import_taxons(client, row) }
  results
end

def import_taxons(client, category)
  result = {}
  taxonomy = client.taxonomies.find_by("lower(name) = ?", "categories")
  parent_taxon = client.taxons.find_by("lower(name) = ?", "categories")
  taxon = taxonomy.taxons.find_by(name: category[1].strip, client_id: client.id, shopify_id: category[0].strip, parent_id: parent_taxon.try(:id))

  unless taxon
    taxon = taxonomy.taxons.new(name: category[1].strip, client_id: client.id, shopify_id: category[0].strip, parent_id: parent_taxon.try(:id))
  end
  # taxon.permalink = "categories/#{category[1].stripe.downcase.parameterize}"
  taxon.slug = category[1].stripe.downcase.parameterize
  taxon.meta_title = category[1].strip
  taxon.meta_description = category[1].strip
  taxon.description = category[1].strip

  result[:shopify_id] = taxon.shopify_id
  unless taxon.save
    result[:errors] = taxon.errors.full_messages
  end
  result
end

client = Spree::Client.find(46)
var_import = import_categories(client, "shopify/scripts/v2/files/collections")
