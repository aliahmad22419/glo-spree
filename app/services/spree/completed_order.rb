module Spree
  class CompletedOrder
    prepend Spree::ServiceModule::Base

    def call(order:)
      # run :ensure_order_is_completed
      run :save_exchange_rates
      run :post_review
      # FIXME orders method 'save_line_item_exchange_rates' sounds best here
    end

    private

    def ensure_order_is_completed(order:)
      return false unless order.complete?
    end

    def save_exchange_rates(order:)
      order.line_items.each { |item| item.update_exchange_rates }
      success(order: order)
    end

    def post_review(order:)
      headers = { apikey: ENV["REVIEW_API_KEY"], store: ENV["REVIEW_STORE_ID"] }
      query = { name: order.email, email: order.email, order_id: order.number, products: []}

      code = order.store.code
      site_url = ENV["REVIEW_STORE_URL"]
      site_url = "#{site_url}/#{code}" unless code == "sg"

      order.line_items.map do |line_item|
         query[:products] << {
           sku: line_item.product.sku,
           name: line_item.product.name,
           image: (line_item.product.images[0].styles[0][:url] rescue nil),
           pageUrl: "#{site_url}/#{line_item.product.slug}"
         }
      end

      response = HTTParty.post("https://api.reviews.co.uk/product/invitation", headers: headers, query: query.with_indifferent_access)

      return failure([], response["message"]) if response["status"] = "error"
      success(order: order)
    end
  end
end
