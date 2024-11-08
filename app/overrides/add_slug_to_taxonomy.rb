Deface::Override.new(
		virtual_path: 'spree/admin/taxonomies/_form',
		name: 'slug_to_taxonomy',
		insert_bottom: '[data-hook="admin_inside_taxonomy_form"]',
		text: "<%= f.label :slug, Spree.t(:slug) %>
           <%= f.text_field :slug, class: 'form-control' %>"
)
