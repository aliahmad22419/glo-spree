order = printable.printable

sold_to = order.bill_address
deliver_to = order.ship_address
vendor = Spree::Vendor.find_by_id printable.vendor_id
vendor_address = vendor&.ship_address

header = []
header << "SOLD TO"
header << "DELIVER TO"
header << "SELLER"

sold = ""
if sold_to.present?
  sold << "#{sold_to.firstname} #{sold_to.lastname}\n"
  sold << "Apt/Unit #: #{sold_to.apartment_no.present? ? sold_to.apartment_no : 'N/A'}\n"
  sold << "Building/Estate: #{sold_to.estate_name.present? ? sold_to.estate_name : 'N/A'}\n"
  sold << "Address: #{sold_to.address1}\n"
  sold << "#{sold_to.address2}\n" if sold_to.address2.present?
  sold << "Region: #{sold_to.region.present? ? sold_to.region : 'N/A'}\n"
  sold << "District: #{sold_to.district.present? ? sold_to.district : 'N/A'}\n"
  sold << "State: #{sold_to.state&.present? ? sold_to.state.name : 'N/A'}\n"
  sold << "City: #{sold_to.city.present? ? sold_to.city : 'N/A'}\n"
  sold << "Postcode: #{sold_to.zipcode.present? ? sold_to.zipcode : 'N/A'}\n"
  sold << "Country: #{sold_to.country&.name.present? ? sold_to.country.name : 'N/A'}\n"
  sold << "Tel: #{sold_to.phone.present? ? sold_to.phone : 'N/A'}\n"
end

deliver = ""
if deliver_to.present?
  deliver << "#{deliver_to.firstname} #{deliver_to.lastname}\n"
  deliver << "Apt/Unit #: #{deliver_to.apartment_no.present? ? deliver_to.apartment_no : 'N/A'}\n"
  deliver << "Building/Estate: #{deliver_to.estate_name.present? ? deliver_to.estate_name : 'N/A'}\n"
  deliver << "Address: #{deliver_to.address1}\n"
  deliver << "#{deliver_to.address2}\n" if deliver_to.address2.present?
  deliver << "Region: #{deliver_to.region.present? ? deliver_to.region : 'N/A'}\n"
  deliver << "District: #{deliver_to.district.present? ? deliver_to.district : 'N/A'}\n"
  deliver << "State: #{deliver_to.state&.present? ? sold_to.state.name : 'N/A'}\n"
  deliver << "City: #{deliver_to.city.present? ? deliver_to.city : 'N/A'}\n"
  deliver << "Postcode: #{deliver_to.zipcode.present? ? deliver_to.zipcode : 'N/A'}\n"
  deliver << "Country: #{deliver_to.country&.name.present? ? deliver_to.country.name : 'N/A'}\n"
  deliver << "Tel: #{deliver_to.phone.present? ? deliver_to.phone : 'N/A'}\n"
end

seller = "#{vendor.present? ? vendor.name : 'N/A'}\n"
if vendor_address.present?
  seller << "#{vendor_address.firstname} #{vendor_address.lastname}\n"
  seller << "Apt/Unit #: #{vendor_address.apartment_no.present? ? vendor_address.apartment_no : 'N/A'}\n"
  seller << "Building/Estate: #{vendor_address.estate_name.present? ? vendor_address.estate_name : 'N/A'}\n"
  seller << "Address: #{vendor_address.address1}\n"
  seller << "#{vendor_address.address2}\n" if vendor_address.address2.present?
  seller << "Region: #{vendor_address.region.present? ? vendor_address.region : 'N/A'}\n"
  seller << "District: #{vendor_address.district.present? ? vendor_address.district : 'N/A'}\n"
  seller << "State: #{vendor_address.state_name.present? ? vendor_address.state_name : 'N/A'}\n"
  seller << "City: #{vendor_address.city.present? ? vendor_address.city : 'N/A'}\n"
  seller << "Postcode: #{vendor_address.zipcode.present? ? vendor_address.zipcode : 'N/A'}\n"
  seller << "Country: #{vendor_address.country&.name.present? ? vendor_address.country.name : 'N/A'}\n"
  seller << "Tel: #{vendor_address.phone.present? ? vendor_address.phone : 'N/A'}\n"
end

data = [header, [sold, deliver, seller]]

pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 3] * 3) do |t|
  t.row(0).font_style = :bold
  t.row(0).border_widths = [1, 1, 0, 1]
  t.row(1).border_widths = [0, 1, 1, 1]
  t.cells.padding = 10
end
