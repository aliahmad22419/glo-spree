font_style = {
  face: 'Arial',
  size: Spree::PrintInvoice::Config[:font_size]
}

prawn_document(force_download: true) do |pdf|
  ["Arabic", "Eng"].each do |lng|
    pdf.font_families.update("Arial#{lng}" => {
      normal: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/Arial#{lng}-Regular.ttf", font: "Arial#{lng}" },
      bold: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/Arial#{lng}-Bold.ttf", font: "Arial#{lng}" },
      italic: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/Arial#{lng}-Italic.ttf", font: "Arial#{lng}" },
      bold_italic: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/Arial#{lng}-BoldItalic.ttf", font: "Arial#{lng}" }
    })
  end

  ["JP", "SC", "Thai"].each do |lng|
    pdf.font_families.update("NotoSans#{lng}" => {
      normal: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Regular.ttf",
      bold: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Bold.ttf",
      italic: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Regular.ttf",
      bold_italic: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Bold.ttf"
    })
  end

  pdf.define_grid(columns: 5, rows: 8, gutter: 10)

  # 'Arial' being used as default font
  pdf.font "ArialEng", style: :normal, size: font_style[:size]
  pdf.fallback_fonts ['ArialEng', 'ArialArabic', 'NotoSansJP', 'NotoSansSC', 'NotoSansThai']

  # HEADER
  pdf.repeat(:all) do
    pdf.canvas do
      render 'spree/printables/shared/giftcard/header', pdf: pdf, printable: @doc
    end
  end

  # CONTENT
  @config = @doc.pdf_config
  @doc.set_locale
  pdf.grid([1,0], [6,4]).bounding_box do
    render 'spree/printables/shared/givex_card/givex', pdf: pdf, givex: @doc.printable
  end

  # Footer
  if pdf.page_count == pdf.page_number
    render 'spree/printables/shared/giftcard/footer', pdf: pdf
  end

  # Page Number
  # render 'spree/printables/shared/page_number', pdf: pdf
end
