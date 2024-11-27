# hasham need to implement this, for now using for demo
class TsPayGateway < Spree::PaymentMethod


  def payment_source_class
    Spree::TsPayCheckout
  end

  def payment_processable?
    false
  end

end
