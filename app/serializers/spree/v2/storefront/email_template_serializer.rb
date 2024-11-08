module Spree
  module V2
    module Storefront
      class EmailTemplateSerializer < BaseSerializer
        set_type :email_template

        attributes :name, :subject, :html, :email_type
        
      end
    end
  end
end
