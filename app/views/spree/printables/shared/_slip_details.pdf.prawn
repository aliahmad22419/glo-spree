order = printable.printable
vendor_id = printable.vendor_id
shipment_id = printable.shipment_id
complete_payments = order.payments.completed
pdf.move_down 2

header = []
header << "Packingslip #"
header << "Order #"
header << "Order Date:"
header << "Payment Method".pluralize(complete_payments.length)
header << "Shipping Method"

pack = "#{1234567}"

order_number = "#{order.number}"

date = ("#{order.completed_at.strftime("%d %b %Y")}" rescue "")

payment_method = ""
complete_payments.each_with_index do |payment, index|
  card = payment&.card_details
  payment_method << card.name
  payment_method << ", " unless index == complete_payments.length - 1
end

shipment = order.shipments.find(shipment_id)
ship_method = shipment&.shipping_method&.name

data = [header, [pack, order_number, date, payment_method, ship_method]]

pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 5] * 5) do |t|
  t.row(0).font_style = :bold
  t.row(0).border_widths = [1, 1, 0, 1]
  t.row(1).border_widths = [0, 1, 0, 1] # [up, right, bottom, left]
  t.cells.padding = 2
  t.cells.height = 25
end
