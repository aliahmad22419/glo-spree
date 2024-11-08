module LinkPayment
  class SourceGenerator
    def initialize(payment)
      @payment = payment
      @order = @payment.order
      @payment_method = payment.payment_method
      calculate_exchanged_prices
    end

    protected

    def attach_payment
      payment_attributes = @payment.dup.attributes.except("number","state")

      payment_attributes[:source] = Spree::LinkSource.create({
        payment_method_id: @payment.payment_method_id,
        state: :initialized
      })

      @order.payments.create payment_attributes.merge({state: :checkout})
    end
    
    def currency_amount
      {
        value: @order.exchanged_prices[:cents],
        currency: @order.currency,
      }
    end

    def order_reference
      @order.number
    end

    def calculate_exchanged_prices
      @order.price_values(@order.currency)
    end
  end
end