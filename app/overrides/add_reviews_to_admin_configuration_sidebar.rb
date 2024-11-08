Deface::Override.new(
		virtual_path: 'spree/admin/shared/sub_menu/_configuration',
		name: 'converted_admin_configurations_menu',
		insert_bottom: '[data-hook="admin_configurations_sidebar_menu"]',
		text: <<-HTML
                <% if current_spree_user.respond_to?(:has_spree_role?) && current_spree_user.has_spree_role?(:admin) %>
                  <%= configurations_sidebar_menu_item Spree.t(:review_settings, scope: :spree_reviews), edit_admin_review_settings_path %>
                <% end %>
					HTML
)
