header = []

header << "Products"
header << "Qty"

product = ["#{line_item.product.name} - #{line_item.product.vendor_sku}"]
product << line_item.quantity

data = [header, product]
item_text = []

variant_details = ""
line_item.variant&.option_values&.each do |var_opt|
  variant_details += "#{var_opt.option_type&.name}: #{var_opt.name}\n"
end
data << [variant_details, ""]

personalizations = line_item.line_item_customizations.joins(:customization).order("spree_customizations.order, spree_customizations.updated_at ASC")
personalizations.each do |personalization|
  if ["Area", "Field"].include?(personalization.field_type)
    data << ["#{personalization.to_s} - " , ""]
    data << ["#{personalization.text}", ""]
  else
    data << ["#{personalization.to_s(true)}" , ""]
  end
end

if line_item.message.present?
  sender = line_item.order.bill_address
  recipient = line_item.order.ship_address
  data << ["Sender: #{sender.firstname} #{sender.lastname} - Recipient: #{recipient.firstname} #{recipient.lastname}", ""]
  data << ["Message: ", ""]
  data << ["#{line_item.message}", ""]
end
# item << item_text
# item << ""  # item << (render 'spree/printables/shared/totals', pdf: pdf, order: line_item.order)

pdf.table(data, position: :center) do |t|
  t.row(0).font_style = :bold
  t.column_widths = [3 * pdf.bounds.width / 5, 2 * pdf.bounds.width / 5]
  t.cells.border_width = 0
  t.cell_style = { overflow: true }
  t.before_rendering_page do |page|
    page.row(0).border_top_width = 1
    page.row(-1).border_bottom_width = 1
    page.column(0).border_left_width = 1
    page.column(-1).border_right_width = 1
  end

pdf.move_down 10

end
