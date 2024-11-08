module Spree
  module Shared
    class Paginate
      def initialize(collection, params)
        @collection = collection
        @page       = params[:page]
        @per_page   = params[:per_page]
      end

      def call
        return collection unless @page.present?
        
        if collection.kind_of?(Array)
          Kaminari.paginate_array(collection).page(page).per(per_page)
        else
          collection.page(page).per(per_page)
        end
      end

      private

      attr_reader :collection, :page, :per_page
    end
  end
end
