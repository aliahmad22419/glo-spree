module Spree
  module Api
    module V2
      module ResourceSerializerConcern
        extend ActiveSupport::Concern

        def self.included(base)
          serializer_base_name = base.to_s.sub(/^Spree::Api::V2::Platform::/, '').sub(/Serializer$/, '')
          model_klazz = "Spree::#{serializer_base_name}".constantize

          base.set_type model_klazz.json_api_type
          # include standard attributes
          base.attributes(*model_klazz.json_api_columns)
          # include money attributes
          model_klazz.skip_callback(:initialize, :after, :attach_refund_reason_and_payment) if model_klazz == Spree::Refund
          display_getter_methods(model_klazz).each do |method_name|
            base.attribute(method_name) do |object|
              object.public_send(method_name).to_s
            end
          end
          model_klazz.set_callback(:initialize, :after, :attach_refund_reason_and_payment) if model_klazz == Spree::Refund

        end

        def self.display_getter_methods(model_klazz)
          model_klazz.new.methods.find_all do |method_name|
            next unless method_name.to_s.start_with?('display_')
            next if method_name.to_s.end_with?('=')
            next if [Spree::Product, Spree::Variant].include?(model_klazz) && method_name == :display_amount

            method_name
          end
        end
      end
    end
  end
end
