module Spree
  class Printables::Invoice::Adjustment
    extend Spree::DisplayMoney

    attr_accessor :label, :amount, :included

    money_methods :amount

    def initialize(args = {})
      args.each do |key, value|
        send("#{key}=", value)
      end
    end
  end
end
