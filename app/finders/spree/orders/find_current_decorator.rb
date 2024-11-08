# Spree::Orders::FindCurrent.class_eval do
#   def execute(user:, store:, **params)
#     params = params.merge(store_id: store.id)

#     params.delete(:currency)
#     order = incomplete_orders.find_by(params)

#     return order unless order.nil?
#     return if user.nil?

#     order = incomplete_orders.order(created_at: :desc).find_by(store: store, user: user)
#     return order unless order.nil?

#     order_params = { user: user, store: store, token: Spree::GenerateToken.new.call(Spree::Order) }
#     order = Spree::Order.create!(order_params)
#     order
#   end
# end


module Spree
  module Orders
    module FindCurrentDecorator
      def execute(user:, store:, **params)
        params = params.merge(store_id: store.id)

        params.delete(:currency)
        order = incomplete_orders.find_by(params)

        return order unless order.nil?
        return if user.nil?

        order = incomplete_orders.order(created_at: :desc).find_by(store: store, user: user)
        return order unless order.nil?

        order_params = { user: user, store: store, token: Spree::GenerateToken.new.call(Spree::Order) }
        order = Spree::Order.create!(order_params)
        order
      end
    end
  end
end

::Spree::Orders::FindCurrent.prepend(Spree::Orders::FindCurrentDecorator)
