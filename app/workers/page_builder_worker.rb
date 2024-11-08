class PageBuilderWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'page_builder'

	def copy_layout copy_to, copy_from
		copy_from.html_components.each do |html_component|
			publish_html_layout_component = copy_to.html_components.create(name: html_component.name, type_of_component: html_component.type_of_component, position: html_component.position, heading: html_component.heading, no_of_images: html_component.no_of_images)
			html_component.html_ui_blocks.each do |component|
				html_block = publish_html_layout_component.html_ui_blocks.new(component.dup.attributes)
				html_block.html_links = component.html_links.collect { |link| link.dup } if component.html_links
				comp_image = component.image
				if comp_image && comp_image&.attachment
					img = Spree::Image.new(viewable_type: "Spree::HtmlUiBlock", attachment_file_name: comp_image.attachment_file_name)
					img.attachment.attach(comp_image&.attachment.blob)
					img.save!
					html_block.attachment_id = img.id
				else
					html_block.attachment_id = nil
				end
				html_block.save
				if component.html_ui_block_sections
					component.html_ui_block_sections.each do |section|
						new_section = html_block.html_ui_block_sections.new(section.dup.attributes)
						new_section.html_links = section.html_links.collect { |link| link.dup } if section.html_links
						sec_image = section.image
						if sec_image && sec_image&.attachment
							img = Spree::Image.new(viewable_type: "Spree::HtmlUiBlockSection", attachment_file_name: sec_image.attachment_file_name)
							img.attachment.attach(sec_image&.attachment.blob)
							img.save!
							new_section.attachment_id = img.id
						else
							new_section.attachment_id = nil
						end
						new_section.save
					end
				end
			end
		end
	end

  def perform(copy_to, copy_from, copy_from_layout)
		if copy_from_layout
			html_page = Spree::HtmlPage.find(copy_to)
			layout = Spree::HtmlLayout.find(copy_from)
			publish_layout = html_page.publish_html_layouts.create(name: layout.name, active: true, publish: true,type_of_layout: "full_page")
      layout.update_column(:publish, true)
			copy_layout publish_layout, layout
		else
			publish_layout = Spree::PublishHtmlLayout.find(copy_from)
			layout = Spree::HtmlLayout.find(copy_to)
      layout.update_column(:publish, false)
			layout.html_components.destroy_all
			copy_layout layout, publish_layout
		end
		layout&.html_page&.store&.clear_store_cache()
  end
end
