
module Spo
  class Checkout

    def call(user:, store:, currency:, order_params:, line_item_options:)
      @store = store
      order_result = create_order(user, currency, order_params)
      @order = order_result.value
      result = add_line_item(line_item_options[:options])
      assign_addesses
      
      return result unless result.success?
      @line_item = @order.line_items.last
      @line_item.line_item_customizations.create(line_item_options[:customizations_attributes])
      update_payment_cart_options(line_item_options[:amount])
      @order.create_proposed_shipments
      order_result
    end

    def ts_card_topup(order: ,card_params:)
      ts_giftcard = Spo::TsGiftcard.new(order.store,credential(card_params))
      response = ts_giftcard.topup(card_params)
      order.ts_fullfilled! if response.code == 200
      response
    end

    def ts_send_email(store: ,emails_params:)
      ts_giftcard = Spo::TsGiftcard.new(store)
      ts_giftcard.send_emails(emails_params)
    end

    def ts_card_activation(order: ,card_params:)
      ts_giftcard = Spo::TsGiftcard.new(order.store,credential(card_params))
      response = ts_giftcard.activation(card_params)
      order.ts_fullfilled! if response.code == 200
      response
    end

    private
    def assign_addesses
      address = @store.pickup_address.clone&.attributes
      @order.create_bill_address(address)
      @order.create_ship_address(address)
      @order.save
    end

    def create_order(user, currency, order_params)
      order_options = {
        user: nil,
        store: @store,
        currency: currency,
        order_params: order_params
      }
      Spree::Cart::Create.call(order_options)
    end

    def credential(params)
      params["credential"] && params["credential"]["ts_email"] && params["credential"]["ts_password"] ? params["credential"] : nil
    end

    def add_line_item(options)   
      variant = @store.products.find(options[:sku])&.master
      result = Spree::Cart::AddItem.call(
        order: @order,
        variant: variant,
        quantity: 1,
        options: options.merge({store_id: @store.id})
      )
      result
    end

    def update_payment_cart_options(amount)
      price_options = { price: amount, sub_total: amount, pre_tax_amount: amount }
      @line_item.update_columns(price_options)
      Spree::OrderUpdater.new(@order).update_totals
      Spree::TaxRate.adjust(@order, [@line_item])
    end

  end
end