module UiLinksHelper
  def valid_url(link, subfolding, store_code)
    uri = URI.parse link rescue link = "#"
    return link if uri.is_a?(URI::HTTP) || link['www.'].present?
    return "/" + store_code + "/#{link}" if subfolding
    return "/#{link}"
  end

  def get_product_image_url img, detail_page_size
    return rails_public_blob_url(img&.attachment&.variant(resize: detail_page_size), only_path: true) rescue "#"
  end
end
