module Spree
  class PaymentMethod::CashOnDelivery < PaymentMethod

    preference :bank, :string, default: nil
    preference :account_number, :string, default: nil
    preference :routing_number, :string, default: nil
    preference :IBAN, :string, default: nil
    preference :BIC, :string, default: nil
        
    def actions
      %w{capture void}
    end

    def can_capture?(payment)
      ['checkout', 'pending'].include?(payment.state)
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      payment.state != 'void'
    end

    def capture(*args)
      ActiveMerchant::Billing::Response.new(true, "", {}, {})
    end

    def cancel(response); end

    def void(*args)
      ActiveMerchant::Billing::Response.new(true, "", {}, {})
    end

    def source_required?
      false
    end
  end
end
