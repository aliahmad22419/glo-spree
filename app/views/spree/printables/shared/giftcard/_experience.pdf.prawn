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

pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.number') }}</b><b>:</b> #{@doc.card_number}", inline_format: true, size: normal_text_size, align: :center
pdf.move_down 10

expiry_date = @doc.expiry_date.to_s
if expiry_date.present?
  pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.expiry') }}</b><b>:</b> #{Time.parse(expiry_date).strftime('%d %b %y')}", inline_format: true, size: normal_text_size, align: :center
  pdf.move_down 10
else
   pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.expiry') }}</b><b>:</b> No Expiry", inline_format: true, size: normal_text_size, align: :center
   pdf.move_down 10
end
pdf.text "<b>#{I18n.with_locale(@doc.store_locale) { I18n.t('pdf.gift_card.details.order_reference') }}</b><b>:</b> #{giftcard&.order.number}", inline_format: true, size: normal_text_size, align: :center

pdf.move_down space

pdf.stroke_horizontal_rule
pdf.move_down space

# Print QR image with fixed width and height
qr_image_url = giftcard.get_s3_object_url(giftcard.qrcode_key)
if qr_image_url.present?
  pdf.image open(qr_image_url), position: :center, fit: [85, 85]
  pdf.move_down space
end

pdf.text @config[:qr_code], size: normal_text_size, align: :center
if @config[:qr_code].present? || qr_image_url.present?
  pdf.move_down space
  pdf.stroke_horizontal_rule
end

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
