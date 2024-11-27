class Spree::LinkSource < Spree::Base
  has_one :payment, as: :source
  has_many :log_entries, as: :source
  alias_method :webhook_responses, :log_entries
  
  belongs_to :payment_method
  belongs_to :user, class_name: "Spree::User", foreign_key: 'user_id', optional: true

  enum state: { initialized: 0, pending: 1, completed: 2, expired: 3, failed: 4}

  after_update :process_source!, if: :completed?
  after_update :fail_payment!, if: :failed?

  def display_number
    return "" unless last_4 = meta&.[]('card_summary')
    
    last_4
  end

  private

  def process_source!
    payment.order.process_payments!
    payment.order.next! if !payment.order.reload.completed?
  rescue Exception => exception
    webhook_responses.create(details: { key: 'Processing', value: exception.inspect }.to_s)
    
    raise Spree::Core::GatewayError.new exception.message
  end

  def fail_payment!
    payment.failure
  end
  
end
