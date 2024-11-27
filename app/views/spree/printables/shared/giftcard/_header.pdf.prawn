pdf.bounding_box([pdf.bounds.left, pdf.bounds.top], width: pdf.bounds.width, height: pdf.bounds.height - 100) do
  contents = []

   image_url = @doc.logo_url

  # Add a check for image presence
  if image_url.present?

    image_url = open(image_url)
    contents << { image: image_url, position: :center, fit: [pdf.bounds.width, 100] }

    # Table for displaying the image
    pdf.table([contents]) do |t|
      t.cells.border_width = 0
      t.cell_style = { size: 20, valign: :center }
      t.column_widths = [pdf.bounds.width]
    end
  end
end
