def import_csv client, file
  new_option_type_ids = []
  csv_data = CSV.read("#{file}.csv")
  header, *data = csv_data
  data.each { |row| new_option_type_ids << import_option_types(client, row) }
  new_option_type_ids
end

def import_option_types(client, row)
  result = { option_values: [] }
  return { errors: "No name found in file" } unless row[0].present?
  opt = client.option_types.find_or_create_by(name: row[0].strip)
  result[:name] = row[0]
  opt.presentation = row[1].strip if row[1].present?
  opt.presentation = opt.name unless opt.presentation.present?
  if opt.save
    result[:id] = opt.id
    puts "parent id #{opt.id} --#{row[0]}"
    if row[2].present?
      sleep 3
      opt_val = opt.option_values.find_or_create_by(name: row[2].strip)
      opt_val.presentation = row[3].strip if row[3].present?
      opt_val.presentation = opt_val.name unless opt_val.presentation.present?
      opt_result = { name: row[2] }
      if opt_val.save
        opt_result[:id] = opt_val.id
        puts "child id #{opt_val.id} --#{row[2]}"
        puts "count count count count count #{client.option_types.count}"
      else
        opt_result[:errors] = opt_val.errors.full_messages
        puts opt_result[:errors]
      end
      result[:option_values] << opt_result
    else
      result[:option_values] << { errors: "No name for option value found in file" }
    end
  else
    result[:errors] = opt.errors.full_messages
    puts result[:errors]
  end
  result
end

client = Spree::Client.find(46)
imported_ids = import_csv(client, "shopify/scripts/v2/files/scoon_option_types")
