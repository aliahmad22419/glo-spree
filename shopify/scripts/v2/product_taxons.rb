def import_csv client, file
  results = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| results << map_product_with_taxons(client, row) }
  results
end

def map_product_with_taxons(client, mapping)
  result = {}
  product = client.products.find_by_shopify_id(mapping[1].strip)
  taxon = client.taxons.find_by_shopify_id(mapping[0].strip)

  unless product.present?
    result[:error] = "Product not found #{mapping[1]}"
    return result
  end

  unless taxon.present?
    result[:error] = "Taxon not found #{mapping[0]}"
    return result
  end

  client.stores.find_each do |store|
    store.classifications.find_or_create_by(taxon_id: taxon.id, product_id: product.id)
  end

  result
end

client = Spree::Client.find(46)
var_import = import_csv(client, "shopify/scripts/v2/files/curation")
