class SiteMapsWorker
  include Sidekiq::Worker
  require 'archive/zip'
  sidekiq_options queue: 'sitemap'

  def perform()
    options = { priority: 0.5, changefreq: "daily" }

    static_robots = Rails.root.join('public/robots_static.txt')
    FileUtils.rm_rf(Rails.root.join('public/sys-robots.txt').to_s) if File.exist?(static_robots)
    file = File.open('public/sys-robots.txt', 'a')
    file.puts File.read(static_robots) if File.exist?(static_robots)

    Spree::Store.find_each do |store|      
      store_site_map_path = "sitemaps/client_#{store.client.id}#{store.subfoldering_url}"
      SitemapGenerator::Sitemap.sitemaps_path = store_site_map_path

      storefront_url  = "https://#{store.url}" if store.url.present? && store.url["http://"].nil? && store.url["https://"].nil?
      uri = URI.parse(storefront_url) rescue nil
      next unless uri.kind_of?(URI::HTTP)
      SitemapGenerator::Sitemap.default_host = storefront_url

      SitemapGenerator::Sitemap.create do
        if store.client.present?
          store.client.taxons.where("lower(name) <> ?", "categories").find_each do |taxon|
            add("/#{taxon.permalink.gsub("categories/", "")}", options.merge({lastmod: taxon.updated_at.strftime("%Y-%m-%d")}))
          end
        end

        options = { priority: 1, changefreq: "daily" }
        store.products.find_each do |product|
          add("/#{product.slug}", options.merge({lastmod: product.updated_at.strftime("%Y-%m-%d")}))
        end

        # make sure crawlers can find the sitemap
        file.puts "Sitemap: #{store.domain_url}/sitemap.xml"
      end

      map = store.sitemap || store.build_sitemap(client_id: store.client_id)
      map.upload_to_aws("public/#{store_site_map_path}/sitemap.xml.gz", "sitemap.xml")
    end

    file.close
    FileUtils.rm_rf(Dir["public/sitemaps/*"])
  end
end
