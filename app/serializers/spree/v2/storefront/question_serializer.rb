module Spree
  module V2
    module Storefront
      class QuestionSerializer < BaseSerializer
        set_type :question

        attributes :title, :is_replied, :archived, :created_at, :updated_at, :status, :guest_name, :guest_email,
                           :questionable_type, :questionable_id

        attribute :product_attributes do |object|
          product_data = {product_name: "", product_sku: "", product_link:  "", vendor_name: ""}
          product = object&.product
          if product.present?
            product_data["product_name"] = product.name
            product_data["product_sku"] = product.sku
            store_url = object&.store&.url
            product_data["product_link"] =  store_url + "/" + product.slug
            product_data["product_slug"] = product.slug
          end
          product_data
        end


        attribute :order_number do |object|
          object.questionable_id && object.questionable_type == "Spree::Order" ? Spree::Order.find(object.questionable_id).number : nil
        end

        attribute :follow_requester_name do |object|
          object.questionable_id && object.questionable_type == "Spree::Follow" ? object.questionable&.name : nil
        end

        attribute :answer do |object|
          object.answer.title if object.answer
        end

        attribute :answer_create_at do |object|
          object.answer.created_at if object.answer
        end

        attribute :vendor_name do |object|
          object.vendor.name if object.vendor
        end

      end
    end
  end
end
