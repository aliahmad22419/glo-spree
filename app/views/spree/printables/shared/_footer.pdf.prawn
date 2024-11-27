if @doc.old_invoice
  pdf.repeat(:all) do
    pdf.grid([7,0], [7,4]).bounding_box do

      data  = []
      data << [pdf.make_cell(content: Spree.t(:vat, scope: :print_invoice), colspan: 2, align: :center)]
      data << [pdf.make_cell(content: '', colspan: 2)]
      data << [pdf.make_cell(content: Spree::PrintInvoice::Config[:footer_left],  align: :left),
      pdf.make_cell(content: Spree::PrintInvoice::Config[:footer_right], align: :right)]

      pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2]) do
        row(0..2).style borders: []
      end
    end
  end
else
  pdf.bounding_box [pdf.bounds.left + 60, pdf.bounds.bottom + 140], width: pdf.bounds.width - 130, height: pdf.bounds.height - 80 do
    order = printable.printable
    deliver_to = order.ship_address
    vendor = Spree::Vendor.find_by_id printable.vendor_id
    client = vendor&.client
    image_url = client&.active_storge_url(client&.logo)
    vendor_address = vendor&.ship_address

    deliver = "<b>Delivery Address</b>\n\n"
    deliver << "#{order.number}\n"
    if deliver_to.present?
      deliver << "#{deliver_to.firstname} #{deliver_to.lastname}\n"
      deliver << "#{deliver_to.address1}\n"
      deliver << "#{deliver_to.address2}" if deliver_to.address2.present?
      deliver << ", #{deliver_to.apartment_no}" if deliver_to.apartment_no.present?
      deliver << "\n#{deliver_to.country.name}" if deliver_to.country&.name.present?
      deliver << "\n#{deliver_to.city}" if deliver_to.city.present?
      deliver << ", #{deliver_to.state_name}" if deliver_to.state_name.present?
      deliver << ", #{deliver_to.region}" if deliver_to.region.present?
      # deliver << "Building/Estate: #{deliver_to.estate_name}\n" if deliver_to.estate_name.present?
      # deliver << "District: #{deliver_to.district}\n" if deliver_to.district.present?
      deliver << "\n#{deliver_to.zipcode}" if deliver_to.zipcode.present?
      deliver << "\n#{deliver_to.phone}" if deliver_to.phone.present?
    end

    seller = "<b>Seller and Return Address</b>\n\n"
    seller << "#{vendor.present? ? vendor.name : 'N/A'}\n"
    if vendor_address.present?
      seller << "#{vendor_address.firstname} #{vendor_address.lastname}\n"
      seller << "#{vendor_address.address1}\n"
      seller << "#{vendor_address.address2}" if vendor_address.address2.present?
      seller << ", #{vendor_address.apartment_no}" if vendor_address.apartment_no.present?
      seller << "\n#{vendor_address.country.name}" if vendor_address.country&.name.present?
      seller << "\n#{vendor_address.city}" if vendor_address.city.present?
      seller << ", #{vendor_address.state_name}" if vendor_address.state_name.present?
      seller << ", #{vendor_address.region}" if vendor_address.region.present?
      # seller << "Building/Estate: #{vendor_address.estate_name}\n" if vendor_address.estate_name.present?
      # seller << "District: #{vendor_address.district}\n" if vendor_address.district.present?
      seller << "\n#{vendor_address.zipcode}" if vendor_address.zipcode.present?
      seller << "\n#{vendor_address.phone}" if vendor_address.phone.present?
    end

    image_url = {image: open(image_url), position: :right, fit: [30, 30]} if image_url.present?

    pdf.table([[deliver, image_url, seller, image_url]]) do |t|
      t.rows(0).column_widths = [100, 20]
      t.cells.border_width = 0
      t.cell_style = { inline_format: true }
    end
  end
end
