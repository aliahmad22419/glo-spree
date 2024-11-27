module Spree
  module ReimbursementDecorator
    def self.prepended(base)
      base.enum status: { pending: 1, completed: 2 }
    end
  end
end

::Spree::Reimbursement.prepend Spree::ReimbursementDecorator if ::Spree::Reimbursement.included_modules.exclude?(Spree::ReimbursementDecorator)
