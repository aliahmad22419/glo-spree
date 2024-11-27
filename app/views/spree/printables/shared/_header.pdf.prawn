if @doc.old_invoice
  order = printable&.printable
  store = order&.store
  client = store.client
  # im = (Rails.application.assets || ::Sprockets::Railtie.build_environment(Rails.application)).find_asset(Spree::PrintInvoice::Config[:logo_path])

  # if im && File.exist?(im.filename)
  #   pdf.image im.filename, vposition: :top, height: 40, scale: Spree::PrintInvoice::Config[:logo_scale]
  # end

  contents = []
  image_url = @invoice&.active_storge_url(@invoice&.image)
  if image_url.present?
    image_url = open(image_url)
    contents << { image: image_url, position: :left, fit: [pdf.bounds.width, 100] }
    pdf.grid([0,0], [1,4]).bounding_box do
      pdf.table([contents]) do |t|
        t.cells.border_width = 0
        t.cell_style = { size: 20, align: :left }
        t.column_widths = [4 * pdf.bounds.width / 5, pdf.bounds.width / 5]
      end
    end
  end

  pdf.grid([0,3], [1,4]).bounding_box do
    if @invoice&.brand.present?
      pdf.text @invoice&.brand, align: :right, style: :bold, size: 18
      pdf.move_down 4
    end
    if @invoice&.address.present?
      pdf.text @invoice&.address, align: :right
      pdf.move_down 2
    end
    if @invoice&.phone.present?
      pdf.text 'T: ' + @invoice&.phone, align: :right
      pdf.move_down 2
    end
    pdf.text @invoice&.email, align: :right
  end

  pdf.grid([1,0], [1,4]).bounding_box do
    pdf.text 'Sales Receipt', align: :right, style: :bold, size: 18
    pdf.move_down 4
    if order.completed_at.present?
      pdf.text 'Receipt Number: ' + order.completed_at&.to_datetime&.strftime("%Y%m%d%H%M"), align: :right
      pdf.move_down 2
      pdf.text 'Purchase Date: ' + order.completed_at&.to_datetime&.strftime("%Y-%m-%d"), align: :right
      pdf.move_down 2
    end
    pdf.text 'Order Number: ' + order.number, align: :right
  end
else
  pdf.bounding_box [pdf.bounds.left + 20, pdf.bounds.top], width: pdf.bounds.width - 20, height: pdf.bounds.height - 100 do
    contents = []
    vendor = Spree::Vendor.find_by_id printable.vendor_id
    client = vendor&.client
    image_url = client&.active_storge_url(client&.logo)

    contents << "THANK YOU FOR YOUR ORDER"
    if image_url.present?
      image_url = open(image_url)
      contents << { image: image_url, position: :right, fit: [50, 50]}
    end

    pdf.table([contents]) do |t|
      t.cells.border_width = 0
      t.cell_style = { size: 20, valign: :center }
      t.column_widths = [4 * pdf.bounds.width / 5, pdf.bounds.width / 5]
    end

    pdf.move_down 15

    render 'spree/printables/shared/slip_details', pdf: pdf, printable: printable
    render 'spree/printables/shared/address_details', pdf: pdf, printable: printable
  end
end
