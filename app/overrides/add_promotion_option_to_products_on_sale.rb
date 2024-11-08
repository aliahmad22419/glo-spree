# Deface::Override.new(
#   virtual_path: 'spree/admin/promotions/actions/_create_adjustment',
# 	name: 'exclude_order_promo_for_on_sale_products',
# 	insert_bottom: 'div.calculator-fields > div.row',
# 	text: <<-HTML
#           <% if promotion_action.type.eql?("Spree::Promotion::Actions::CreateAdjustment") %>
#             <div class="form-group col-12 mb-0" style="margin-left: 15px; margin-right: 15px;">
#               <% exclude_field = "promotion[promotion_actions_attributes][" + promotion_action.id.to_s + "][exclude_sale_items]" %>
#               <%= hidden_field_tag exclude_field, 'false' %>
#               <%= check_box_tag exclude_field, true, promotion_action.exclude_sale_items %>
#               <%= label_tag :exclude_sale_items, Spree.t("promotion.exclude_for_product_on_sale") %>
#             </div>
#           <% end %>
#         HTML
# )

Deface::Override.new(
  virtual_path: 'spree/admin/promotions/actions/_create_item_adjustments',
	name: 'exclude_line_item_promo_for_on_sale_products',
	insert_bottom: 'div.calculator-fields > div.row',
	text: <<-HTML
          <% if promotion_action.promotion.code.blank? && promotion_action.type.eql?("Spree::Promotion::Actions::CreateItemAdjustments") %>
            <div class="form-group col-12 mb-0" style="margin-left: 15px; margin-right: 15px;">
              <% exclude_field = "promotion[promotion_actions_attributes][" + promotion_action.id.to_s + "][exclude_sale_items]" %>
              <%= hidden_field_tag exclude_field, 'false' %>
              <%= check_box_tag exclude_field, true, promotion_action.exclude_sale_items %>
              <%= label_tag :exclude_sale_items, Spree.t("promotion.exclude_for_product_on_sale") %>
            </div>
         <% end %>
        HTML
)
