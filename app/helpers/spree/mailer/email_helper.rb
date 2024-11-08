module Spree
  module Mailer
    module EmailHelper
      def str_to_a email_addresses
        email_addresses.split(',').map(&:strip) rescue []
      end
    end
  end
end
