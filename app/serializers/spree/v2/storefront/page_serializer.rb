module Spree
  module V2
    module Storefront
      class PageSerializer < BaseSerializer
        set_type :page

        attributes :title, :sort_order, :status, :heading, :content, :created_at,:meta_desc, :url, :static_page

        attribute :store_ids do |object|
          object&.store_ids&.map{|id| id.to_s}
        end

      end
    end
  end
end
