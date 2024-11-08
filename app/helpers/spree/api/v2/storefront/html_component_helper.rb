module Spree::Api::V2::Storefront::HtmlComponentHelper

  def get_image_url(component)
    attachment = component&.image&.attachment
    url = ""
    url = component.active_storge_url(attachment) if attachment
    return url
  end

  def link_with_subdomain_or_not(subfolding, store_code, url)
    return "/" + store_code + url if subfolding
    return url
  end

  def home_url(home_url)
    return "http://" + home_url
  end

end
