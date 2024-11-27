prices = order.price_values(order.currency, @doc.vendor_id)[:prices]
currency_symbol = Spree::Money.new(order.currency).currency.symbol

if @doc.old_invoice
    # TOTALS
  totals = []

  # Subtotal

  totals << [pdf.make_cell(content: Spree.t(:subtotal)), currency_symbol + prices[:item_total]]

  # Adjustments
  # invoice_adjustments = invoice.adjustments

  # inclusive_taxes = invoice_adjustments.select{ |adj| adj.included == true}.map(&:label).join(',')
  # totals << [pdf.make_cell(content: inclusive_taxes), currency_symbol + prices[:included_tax_total]] if inclusive_taxes.present?
  #
  # exclusive_taxes = invoice_adjustments.select{ |adj| adj.included == false}.map(&:label).join(',')
  # totals << [pdf.make_cell(content: exclusive_taxes), currency_symbol + prices[:additional_tax_total]] if exclusive_taxes.present?

  # Taxes
  totals << [pdf.make_cell(content: 'Inclusive Tax'), currency_symbol + prices[:included_tax_total]] if prices[:included_tax_total].to_f != 0.0
  totals << [pdf.make_cell(content: 'Exclusive Tax'), currency_symbol + prices[:additional_tax_total]] if prices[:additional_tax_total].to_f != 0.0

  # Shipments
  # shiping_methods = invoice.shipments.map{ |ship| ship.shipping_method.name}.join(',')
  totals << [pdf.make_cell(content: 'Shipping'), currency_symbol + prices[:ship_total]]

  # Totals
  totals << [pdf.make_cell(content: Spree.t(:order_total)), currency_symbol + (prices[:payable_amount].to_f + prices[:gc_total].to_f).to_s]

  payment = order.payments.last
  # Payments
  total_payments = 0.0

  totals << [
        pdf.make_cell(
          content: Spree.t(:payment_via,
          gateway: (payment&.source_type&.demodulize || Spree.t(:unprocessed, scope: :print_invoice)),
          number: payment.number,
          date: I18n.l(payment.updated_at.to_date, format: :long),
          scope: :print_invoice)
        ),
        currency_symbol + (prices[:payable_amount].to_f + prices[:gc_total].to_f).to_s
      ]
      total_payments += payment.amount

  totals_table_width = [0.875, 0.125].map { |w| w * pdf.bounds.width }
  pdf.table(totals, column_widths: totals_table_width) do
    row(0..7).style align: :right
    column(0).style borders: [], font_style: :bold
  end
else
  header = "Price"
  item =  "#{prices[:payable_amount]} \n\n"
  item <<  "Total #{prices[:payable_amount]} \n\n\n"
  item << "Delivery #{prices[:ship_total]} \n\n"
  item << "Grand Total #{prices[:total]} \n\n"

  pdf.make_table([[header], [item]]) do |t|
    t.row(0).font_style = :bold
    t.cells.border_width = 0
    t.column_widths = 150
  end
end
