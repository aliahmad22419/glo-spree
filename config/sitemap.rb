SitemapGenerator::Sitemap.default_host = "https://www.giftslessordinary.com"
# The root path '/' and sitemap index file are added automatically.
# Links are added to the Sitemap in the order they are specified.
# Defaults: priority: 0.5, changefreq: 'weekly', lastmod: Time.now, host: default_host

# If using Heroku or similar service where you want sitemaps to live in S3 you'll need to setup these settings.
# Pick a place safe to write the files
SitemapGenerator::Sitemap.public_path = (ENV["SITE_MAP_PATH"] || "public/")
# SitemapGenerator::Sitemap.adapter = SitemapGenerator::S3Adapter.new(aws_access_key_id:     ENV["BUCKETEER_AWS_ACCESS_KEY_ID"],
#                                                                     aws_secret_access_key: ENV["BUCKETEER_AWS_SECRET_ACCESS_KEY"],
#                                                                     fog_provider:          'AWS',
#                                                                     fog_directory:         ENV["BUCKETEER_BUCKET_NAME"],
#                                                                     fog_region:            ENV["BUCKETEER_AWS_REGION"])
# SitemapGenerator::Sitemap.sitemaps_host = "http://#{ENV["BUCKETEER_BUCKET_NAME"]}.s3.amazonaws.com/"

options = { priority: 0.5, changefreq: "daily" }

clients = Spree::Client.all

clients.find_each do |client|
  client.stores.find_each do |store|
    site_map_path = "sitemaps/#{client.name.downcase.gsub(' ', '-')}/#{store.code}" # sitemaps-#{Date.today.to_s}
    SitemapGenerator::Sitemap.sitemaps_path = site_map_path

    storefront_url  = "https://#{store.url}" if store.url["http://"].nil? && store.url["https://"].nil?
    SitemapGenerator::Sitemap.default_host = storefront_url

    SitemapGenerator::Sitemap.create do
      client.taxons.where("lower(name) <> ?", "categories").each do |taxon|
        add("/#{taxon.permalink.gsub("categories/", "")}", options.merge({lastmod: taxon.updated_at.strftime("%Y-%m-%d")}))
      end

      options = { priority: 1, changefreq: "daily" }
      store.products.each do |product|
        add("/#{product.slug}", options.merge({lastmod: product.updated_at.strftime("%Y-%m-%d")}))
      end

      # make sure crawlers can find the sitemap
      file = File.open('public/robots.txt', 'a')
      file.puts "Sitemap: #{site_map_path}/sitemap.xml.gz"
      # file.puts "Sitemap: http://#{ENV["BUCKETEER_BUCKET_NAME"]}.s3.amazonaws.com/"
      file.close
    end
  end
end
