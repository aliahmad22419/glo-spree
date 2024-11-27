font_style = {
    face: Spree::PrintInvoice::Config[:font_face],
    size: Spree::PrintInvoice::Config[:font_size]
}
order = doc.printable
client = order&.store&.client
@invoice = order&.store&.invoice_configuration
prawn_document(force_download: true) do |pdf|

    ["JP", "SC", "Thai", "Arabic"].each do |lng|
        pdf.font_families.update( "Sans Serif NotoSans#{lng}" => {
            normal: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Regular.ttf", font: "NotoSans#{lng}" },
            bold: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Bold.ttf", font: "NotoSans#{lng}" },
            italic: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Regular.ttf", font: "NotoSans#{lng}" },
            bold_italic: { file: "#{Rails.root.join('vendor/assets/fonts').to_s}/NotoSans#{lng}-Bold.ttf", font: "NotoSans#{lng}" }
        })
    end

    pdf.define_grid(columns: 5, rows: 8, gutter: 10)
    pdf.font "Sans Serif NotoSansJP", style: :normal, size: font_style[:size]
    pdf.fallback_fonts [ "Sans Serif NotoSansJP", "Sans Serif NotoSansSC" , "Sans Serif NotoSansThai", "Sans Serif NotoSansArabic"]

    if doc.old_invoice

        pdf.repeat(:all) do
            render 'spree/printables/shared/header', pdf: pdf, printable: doc
        end

        # CONTENT
        pdf.grid([2,0], [6,4]).bounding_box do
            # address block on first page only
            if pdf.page_number == 1
                render 'spree/printables/shared/address_block', pdf: pdf, printable: doc
            end
            pdf.move_down 10
            render 'spree/printables/shared/invoice/items', pdf: pdf, invoice: doc, order: order
            pdf.move_down 10
            render 'spree/printables/shared/totals', pdf: pdf, invoice: doc, order: order
            pdf.move_down 30
            pdf.text @invoice&.notes, align: :right, size: font_style[:size]
        end

        # Footer
        if Spree::PrintInvoice::Config[:use_footer]
            render 'spree/printables/shared/footer', pdf: pdf
        end

        # Page Number
        if Spree::PrintInvoice::Config[:use_page_numbers]
            render 'spree/printables/shared/page_number', pdf: pdf
        end

    else
        image_url = client&.active_storge_url(client&.logo)
        image_url.present? ? pdf.move_down(280) : pdf.move_down(250)
        pdf.bounding_box [pdf.bounds.left + 20, pdf.cursor], width: pdf.bounds.width - 20, height: pdf.bounds.height - 430 do
            order.shipments.find(doc.shipment_id).line_items.each_with_index do |line_item, index|
                render 'spree/printables/shared/line_item_details', pdf: pdf, line_item: line_item, item_number: index
                pdf.move_down 5
            end
        end

        pdf.move_down 200
        pdf.repeat :all do
            render 'spree/printables/shared/header', pdf: pdf, printable: doc
            render 'spree/printables/shared/footer', pdf: pdf, printable: doc # if Spree::PrintInvoice::Config[:use_footer]
        end
        render 'spree/printables/shared/page_number', pdf: pdf # if Spree::PrintInvoice::Config[:use_page_numbers]
    end
end
