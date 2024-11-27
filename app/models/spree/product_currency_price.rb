module Spree
  class ProductCurrencyPrice < Spree::Base
    after_commit -> (obj) { obj.product.reindex }
    scope :in_currency, -> (currency) { where(to_currency: currency) }

    belongs_to :client, class_name: "Spree::Client"
    belongs_to :vendor, class_name: "Spree::Vendor"
    belongs_to :product, class_name: "Spree::Product"

    validates :product_id, uniqueness: { scope: [:client_id, :from_currency, :to_currency] }

    def product_final_price(store_id)
      return local_area_price if local_store_ids.include?(store_id)
      wide_area_price
    end

    def delivery_charges(store_id)
      return (product_final_price(store_id) - (product.on_sale? ? sale_price : price))
    end

    def calculated_tax(store_id)
      tax = taxes.find{ |tax| tax.split(':')[0] == "store#{store_id}" }
      return { amount: 0.0, rate: 0.0 } if tax.blank?
      return ({ amount: tax.split(':')[1].split('-')[0].to_f, rate: tax.split(':')[1].split('-')[1].to_f } rescue { amount: 0.0, rate: 0.0 })
    end

  end
end
