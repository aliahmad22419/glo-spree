module Spree
  module Products
    class Sort
      def initialize(scope, params, current_currency)
        @scope    = scope
        @store = params[:store]
        @sort     = params[:sort]
        @currency = params[:currency] || current_currency
        @taxon = params[:q].present? ? params[:q][:taxons_permalink_eq] || nil : nil
        @taxon_id = params[:q].present? ? params[:q][:taxons_id_eq] || nil : nil
        @client = params[:client_id]
        @store_id = @store&.id || (params[:q].present? ? params[:q][:stores_id_in] || nil : nil)
      end

      def products
      end

      def call
        # undo order applied before
        products = scope.unscope(:order)
        products = updated_at(products)
        products = created_at(products)
        products = price(products)
        products = name(products)
        products = best_seller(products)
        products = manually(products)

        products
      end

      private

      attr_reader :sort, :scope, :currency, :store, :taxon, :client, :taxon_id, :store_id

      def desc_order
        @desc_order ||= String(sort)[0] == '-'
      end

      def sort_field
        @sort_field ||= desc_order ? sort[1..-1] : sort
      end

      def updated_at?
        sort_field == 'updated_at'
      end

      def created_at?
        sort_field == 'created_at'
      end

      def price?
        sort_field == 'price'
      end

      def name?
        sort_field == 'name'
      end

      def best_seller?
        sort_field == 'best_seller'
      end

      def manually?
        sort_field == 'manually'
      end

      def order_direction
        desc_order ? :desc : :asc
      end

      def updated_at(products)
        return products unless updated_at?

        products.order(updated_at: order_direction)
      end

      def created_at(products)
        return products unless created_at?

        products.order(created_at: order_direction)
      end

      def price(products)
        return products unless price?

        direction = (desc_order ? -1 : 1)
        products = products.sort_by{ |p| direction * p.product_price(currency, store).to_f }
      end

      def name(products)
        return products unless name?
        products.order(name: order_direction)
      end

      def best_seller(products)
        return products unless best_seller?
        return products if taxon.blank? || store.blank?
        taxon_record_id = Spree::Taxon.where(permalink: taxon, client_id: client)&.first&.id
        return products if taxon_record_id.blank?
        # products.joins(:classifications).where("spree_products_taxons.product_id=spree_products.id AND spree_products_taxons.taxon_id=#{taxon_record_id}").order('spree_products_taxons.position ASC')
        products.joins(:classifications).where("spree_products_taxons.product_id=spree_products.id AND spree_products_taxons.taxon_id=#{taxon_record_id} AND spree_products_taxons.store_id=#{store.id}").order('spree_products_taxons.position ASC')
      end

      def manually(products)
        return products unless manually?
        return products if taxon_id.blank? || store_id.blank?
        products.joins(:classifications).where("spree_products_taxons.product_id=spree_products.id AND spree_products_taxons.taxon_id=#{taxon_id} AND spree_products_taxons.store_id=#{store_id}").order('spree_products_taxons.position ASC')
      end

    end
  end
end
