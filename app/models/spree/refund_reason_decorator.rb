Spree::RefundReason.class_eval do
    # clear all validations for name
    _validators.reject!{ |key, value| key == :name }
    _validate_callbacks.each do |callback|
        next if callback.filter.eql?(:validate_associated_records_for_refunds)
        callback.raw_filter.attributes.reject! { |key| key == :name } if callback.raw_filter.respond_to?(:attributes)
    end
    
    # add validations for name within client scope
    validates :name, presence: true,
        uniqueness: { case_sensitive: false, allow_blank: true, scope: :client_id }
end