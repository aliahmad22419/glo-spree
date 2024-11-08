module Spree
  module V2
    module Storefront
      class PropertySerializer < BaseSerializer
        set_type  :property

        attribute :id, :name, :presentation, :filterable, :values

        attribute :values do |object|
          object&.values.split(',')
        end

        attribute :store_ids do |object|
          object&.store_ids&.map{|id| id.to_s}
        end
        
      end
    end
  end
end
