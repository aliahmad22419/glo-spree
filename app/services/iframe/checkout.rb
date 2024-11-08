
module Iframe
  class Checkout

    def call(user:, store:, currency:, order_params:, options:)
      @store = store
      @options = options
      order_result = create_order(user, currency, order_params)
      @order = order_result.value
      result = add_line_item
      assign_addesses

      return result unless result.success?
      create_shipments
      order_result
    end

    private
    def assign_addesses
      address = (@store.v3_flow_address || @store.pickup_address).clone&.attributes
      @order.create_bill_address(address)
      @order.create_ship_address(address)
      @order.save
    end

    def create_shipments
      @order.create_proposed_shipments
      raise "Please configure a shipping method" if @order.shipments.blank?
      @order.shipments.last.update card_generation_datetime: @options.dig(:variants,0,:options,:card_generation_datetime)
      @order.shipments.last.shipping_rates.first.update(selected: true)
      ::Spree::TaxRate.adjust(@order, [@order.shipments.last.reload])
      @order.next! && @order.next! && @order.next!
    end

    def create_order(user, currency, order_params)
      Spree::Cart::Create.call({
        user: nil,
        store: @store,
        currency: currency,
        order_params: order_params
      })
    end

    def add_line_item
      variant_hash = @options.dig(:variants,0)
      Spree::Cart::AddItem.call(
        order: @order,
        variant: Spree::Variant.find_by_id(variant_hash[:id]),
        quantity: variant_hash[:quantity],
        options: variant_hash[:options].merge({store_id: @store.id})
      )
    end

  end
end