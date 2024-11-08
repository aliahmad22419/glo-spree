module ApplicationHelper
  def favicon_url
    return nil unless @store.present? && @store.favicon.attached?

    @store.active_storge_url(@store.favicon)
  end
end
