namespace :db do
  desc "Add Custom JS Links for LayoutSetting"
  task :add_custom_js_links => :environment do
    stores = Spree::Store.all
    stores.each do |store|
      if store.layout_setting&.preferred_custom_js_url.present?
        custom_js_url = store.layout_setting&.preferred_custom_js_url
        store.layout_setting&.preferred_custom_js_links = [{ "name"=> "custom_js", "url"=> custom_js_url }]
        store.layout_setting.save
      end
    end
  end
end