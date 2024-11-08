module Spree
    module V2
      module Storefront
        class ServiceLoginUserSerializer < BaseSerializer
          set_type :user

          attributes :id, :email, :name

          attribute :sub_clients_count do |object|
            object.sub_clients.count
          end

          attribute :clients do |object|
            object&.clients&.map{|c| {name: c&.name, email: c&.email, id: c&.id}}
          end
      end
    end
  end
end
