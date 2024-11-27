pdf.bounding_box [pdf.bounds.left + 70, pdf.bounds.bottom + 50], width: pdf.bounds.width - 140, height: 100 do
  # Add an image
  footer_image_path = @doc.logo_url

  if footer_image_path.present?
    pdf.image open(footer_image_path), fit: [pdf.bounds.width / 2, 50], position: :center
  end

  # Add some space
  pdf.move_down(8)

  # Add the text
  if @doc.card_type == :monetary
    pdf.text @config[:footer], size: 10.5, align: :center
  elsif @doc.card_type == :experiences
    pdf.text @config[:footer], size: 10.5, align: :center
  else
    pdf.text @config[:footer], size: 10.5, align: :center
  end

end
