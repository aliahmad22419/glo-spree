module Spree::PromotionHandler::CartDecorator
  def initialize(order, line_item = nil)
    @order = order
    @line_item = line_item
    @client = @order.store.client
  end

  private

  def promotions
    @client.promotions.find_by_sql(
      "#{order.promotions.where(client_id: @client.id).active.to_sql} UNION
      #{@client.promotions.active.where(code: nil, path: nil).to_sql}"
    )
  end
end

::Spree::PromotionHandler::Cart.prepend Spree::PromotionHandler::CartDecorator
