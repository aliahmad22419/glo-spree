store = order&.store
header = [
  pdf.make_cell(content: Spree.t(:sku)),
  pdf.make_cell(content: Spree.t(:item_description)),
  pdf.make_cell(content: Spree.t(:options)),
  pdf.make_cell(content: Spree.t(:price)),
  pdf.make_cell(content: Spree.t(:qty)),
  pdf.make_cell(content: Spree.t(:total))
]
data = [header]

order.line_items.each do |item|
  prices = item.price_values(store.default_currency)
  row = [
    item.sku,
    item.name,
    item.options_text,
    Spree::Money.new(order.currency).currency.symbol + prices[:sub_total],
    item.quantity,
    Spree::Money.new(order.currency).currency.symbol + prices[:amount]
  ]
  data += [row]
end

column_widths = [0.13, 0.37, 0.185, 0.12, 0.075, 0.12].map { |w| w * pdf.bounds.width }

pdf.table(data, header: true, position: :center, column_widths: column_widths) do
  row(0).style align: :center, font_style: :bold
  column(0..2).style align: :left
  column(3..6).style align: :right
end
