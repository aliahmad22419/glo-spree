Deface::Override.new(
  virtual_path: 'spree/admin/payment_methods/_form',
  name: 'add_braintree_merchant_accounts',
  insert_after: '[data-hook="admin_payment_method_form_fields"]',
  partial: '<% if @object.kind_of?(Spree::Gateway::BraintreeVzeroBase) and @object.persisted? %>
              <%= render "braintree_multi_currency", f: f %>
            <% else %>
              <%= render_original %>
            <% end %>'
)
