class SitemapsController < ApplicationController

  def download
    respond_to do |format|
      format.xml  do
        render xml: { message: "Unauthorized access", status: 403 } and return unless current_store
        unless current_store.sitemap && current_store.sitemap.attachment.attached?
          render xml: { message: "Sitemap data not found", status: 404 } and return
        end
        send_data current_store.sitemap.attachment.blob.download, filename: current_store.sitemap.attachment.filename.to_s, content_type: current_store.sitemap.attachment.content_type, disposition: 'inline'
      end
    end
  end

  def download_robots_sitemap
    file_content = init_robots_file
    
    get_stores.each do |store|
      file_content = "#{file_content}\nSitemap: #{store.domain_url}/sitemap.xml"
    end if file_content

    send_data file_content, type: "text/plain", disposition: "inline", filename: 'robots.txt'
  end

  private

  def get_stores
    return [] unless current_store.present?

    return [current_store] if current_store.subfoldering_url.present?
    Spree::Store.where('spree_stores.url LIKE ?',"#{current_store.get_url_domain(current_store.url, current_store.is_www_domain)}%")
  end

  def init_robots_file
    source_file_path = Rails.root.join('public/robots_static.txt')

    return unless File.exist?(source_file_path)
    File.read source_file_path
  end
end
