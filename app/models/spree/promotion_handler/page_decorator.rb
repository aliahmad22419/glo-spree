module Spree::PromotionHandler::PageDecorator
  def initialize(order, path)
    @order = order
    @path = path.gsub(/\A\//, '')
    @client = @order.store.client
  end

  private

  def promotion
    @promotion ||= @client.promotions.active.find_by(path: path)
  end
end

::Spree::PromotionHandler::Page.prepend Spree::PromotionHandler::PageDecorator
