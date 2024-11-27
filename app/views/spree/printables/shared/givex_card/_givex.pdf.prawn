space = 20
normal_text_size = 10.5
heading_size = 12
editor_space = 12

if @config[:header].present?
  pdf.text @config[:header], size: normal_text_size, align: :center
  pdf.move_down space
  pdf.stroke_horizontal_rule
  pdf.move_down space
end

if @config[:introduction].present?
  pdf.text @config[:introduction], size: normal_text_size, align: :center
  pdf.move_down space
end

if @doc.product_name.present?
  pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.card_type') }}</b><b>:</b> #{@doc.product_name}", inline_format: true, size: normal_text_size, align: :center
  pdf.move_down 10
end

@doc.custom_options.each do |key, value|
  pdf.text "<b>#{key.upcase}:</b> #{value}", inline_format: true, size: normal_text_size, align: :center
  pdf.move_down 10
end

@doc.variant_details.each do |key, value|
  pdf.text "<b>#{key.upcase}:</b> #{value}", inline_format: true, size: normal_text_size, align: :center
  pdf.move_down 10
end

pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.value') }}</b><b>:</b> #{@doc&.card_currency} #{@doc.total}", inline_format: true, size: normal_text_size, align: :center
pdf.move_down 10
pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.number') }}</b><b>:</b> #{@doc.card_number}", inline_format: true, size: normal_text_size, align: :center
pdf.move_down 10

expiry_date = givex.expiry_date
if expiry_date.present?
  pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.expiry') }}</b><b>:</b> #{expiry_date.strftime('%d %b %y')}", inline_format: true, size: normal_text_size, align: :center
  pdf.move_down 10
else
   pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.expiry') }}</b><b>:</b> N/A", inline_format: true, size: normal_text_size, align: :center
   pdf.move_down 10
end
pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.order_reference') }}</b><b>:</b> #{givex&.order.number}", inline_format: true, size: normal_text_size, align: :center

pdf.move_down space

pdf.stroke_horizontal_rule

if @doc.short_description.present? || @doc.long_description.present? || @doc.delivery_details.present?
  pdf.start_new_page
  if @doc.short_description.present?
    pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.product_info') }}</b>", inline_format: true, size: heading_size
    pdf.move_down editor_space
    @doc.render_html(pdf, @doc.short_description)
    pdf.move_down editor_space
  end

  if @doc.long_description.present?
    pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.terms_conditions') }}</b>", inline_format: true, size: heading_size
    pdf.move_down editor_space
    @doc.render_html(pdf, @doc.long_description)
    pdf.move_down editor_space
  end

  if @doc.delivery_details.present?
    pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.redemption_info') }}</b>", inline_format: true, size: heading_size
    pdf.move_down editor_space
    @doc.render_html(pdf, @doc.delivery_details)
    pdf.move_down editor_space
  end

  pdf.stroke_horizontal_rule
end

if @config[:customer_service].present?
  pdf.move_down space
  pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.support_contact') }}</b>", inline_format: true, size: heading_size, align: :center
  pdf.move_down space
  pdf.text @config[:customer_service], size: normal_text_size, align: :center
  pdf.move_down space
  pdf.stroke_horizontal_rule
end
pdf.move_down space
