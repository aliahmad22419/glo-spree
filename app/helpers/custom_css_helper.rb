module CustomCssHelper
  include ActionView::Helpers::NumberHelper
  def valid_style? obj
    obj.values.all?{ |v| v != "" }
  end

  def css_font_family selected_type
    return 'var(--primary-font)' if selected_type == "primary"
    'var(--secondary-font)'
  end

  def css_font_size size
    size = size.to_i / 16.0
    "#{number_with_precision(size, precision: 3)}rem"
  end
end
