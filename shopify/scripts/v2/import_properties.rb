def import_csv client, file
  new_property_ids = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| new_property_ids << import_properties(client, row) }
  new_property_ids
end

def import_properties(client, row)
  result = {}
  return { errors: "No name found in file" } unless row[0].present?
  result[:name] = row[0]
  property = client.properties.find_by("lower(name) = ?", row[0].strip.downcase)
  property = client.properties.new(name: row[0].strip) if property.blank?
  property.presentation = row[1].strip if row[1].present?
  property.presentation = property.name unless property.presentation.present?
  if property.values.present?
    property.values += ", #{row[2].strip}"
  else
    property.values = row[2].strip
  end

  if property.save
    result[:id] = property.id
    puts "parent id #{property.id} --#{row[0]}"
  else
    result[:errors] = property.errors.full_messages
    puts result[:errors]
  end
  result
end

client = Spree::Client.find(46)
imported_ids = import_csv(client, "shopify/scripts/v2/files/scoon_properties")
