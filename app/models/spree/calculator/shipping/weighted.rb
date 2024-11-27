module Spree
  module Calculator::Shipping
    class Weighted < ShippingCalculator

      def self.description
        Spree.t(:weighted_flat_rate)
      end
  
      def compute(package)
        weight = package&.weight
        weighted_cost = self.calculable.weights.find_by('? >= minimum AND ? <= maximum', weight, weight)

        weighted_cost.present? ? weighted_cost.price : [0.0 , true]
      end
    end
  end
end