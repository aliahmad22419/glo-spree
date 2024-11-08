# Spree::Admin::BaseHelper.module_eval do
#   def braintree_multi_currency_fields(object, form)
#     content_tag(:div, get_preference_currencies(object, :currency_merchant_accounts, form))
#   end

#   def get_preference_currencies(object, key, form, value = "")
#     return unless object.has_preference?(key)
#     '<div class="form-group">'.html_safe +
#     text_field_tag("preferred_#{key}[]", value, class: 'col-sm-6') +
#     '<span class="icon icon-minus remove-merchant-account btn btn-danger btn-sm" /></div>'.html_safe
#   end
# end

module Spree::Admin::BaseHelperDecorator
  def braintree_multi_currency_fields(object, form)
    content_tag(:div, get_preference_currencies(object, :currency_merchant_accounts, form))
  end

  def get_preference_currencies(object, key, form, value = "")
    return unless object.has_preference?(key)
    '<div class="form-group">'.html_safe +
    text_field_tag("preferred_#{key}[]", value, class: 'col-sm-6') +
    '<span class="icon icon-minus remove-merchant-account btn btn-danger btn-sm" /></div>'.html_safe
  end
end

Spree::Admin::BaseHelper.prepend  Spree::Admin::BaseHelperDecorator
