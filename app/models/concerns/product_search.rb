module ProductSearch
  def self.included(base)
    base.class_eval do

      searchkick index_name: "spree_products_with_prices", mappings: {
        properties: {
          track_inventory: { type: "boolean" },
          name: { type: "keyword", normalizer: "case_insensetive_normalizer" },
          brand_name: { type: "keyword", normalizer: "case_insensetive_normalizer" },
          meta_keywords: { type: "keyword", normalizer: "case_insensetive_normalizer" },
          stock_status: { type: "boolean" },
          trashbin: { type: "boolean" },
          hide_from_search: { type: "boolean" },
          searchable_stock_product: { type: "boolean" },
          status: { type: "text" },
          count_on_hand: { type: "integer" },
          vendor_id: { type: "integer" },
          vendor_name: { type: "keyword", normalizer: "case_insensetive_normalizer" },
          vendor_sku: { type: "keyword", normalizer: "case_insensetive_normalizer" },
          vendor_slug: { type: "keyword"},
          calculated_days_to_same_country: { type: "integer" },
          calculated_days_to_restricted_area: { type: "integer" },
          calculated_days_to_asia: { type: "integer" },
          calculated_days_to_africa: { type: "integer" },
          calculated_days_to_americas: { type: "integer" },
          calculated_days_to_europe: { type: "integer" },
          calculated_days_to_australia: { type: "integer" },
          created_at: { type: "date", "format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX" },
          updated_at: { type: "date", "format": "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"},
          product_currency_prices: {
            type: "nested",
            properties: {
              to_currency: { type: "keyword" },
              vendor_country_id: { type: "integer" },
              price: { type: "double" },
              sale_price: { type: "double" },
              local_area_price: { type: "double" },
              wide_area_price: { type: "double" },
              restricted_area_price: { type: "double" },
              local_store_ids: { type: "keyword" },
              taxes: { type: "keyword" }
            }
          },
          classifications: {
            type: "nested",
            properties: {
              taxon_id: { type: "integer" },
              store_id: { type: "integer" },
              position: { type: "integer" }
            }
          },
          product_properties: {
            type: "nested",
            properties: {
              value: { type: "keyword", normalizer: "case_insensetive_normalizer" },
              property_id: { type: "integer" }
            }
          }
        }
      },
      settings: {
        # number_of_shards: 1, 5 by default
        number_of_replicas: 3,
        analysis: {
          normalizer: {
            case_insensetive_normalizer: {
              type: "custom",
              # char_filter: [],
              filter: ["lowercase", "asciifolding"]
            }
          }
          # ,
          # analyzer: {
          #   case_insensetive_analyzer: {
          #     tokenizer: "lowercase",
          #     filter: []
          #   }
          # }
        }
      }

      def taxon_id
        options[:taxon_id]
      end

      def search_data
        #   taxon_client_id: taxons[0]&.client_id, # taxons.map(&:client_id).uniq,
        #   taxon_permalink: taxons[0]&.permalink, # taxons.map(&:permalink).uniq,
        vendor_fields = (Hash[(vendor.attributes.slice *%w[name slug]).map{|k,v| ["vendor_#{k}",v]}] rescue {})
        price_fields = %i[to_currency vendor_country_id price sale_price local_area_price wide_area_price restricted_area_price local_store_ids taxes]
        delivery_fields = *%w[same_country restricted_area asia africa americas europe australia]
        delivery_fields = (Hash[attributes.slice *delivery_fields.map{|elem| "calculated_days_to_#{elem}"}] rescue {})
        searchable_stock_product = { "searchable_stock_product": daily_stock? ? stock_products.effective.count > 0 : !type_of?("StockProduct") }

        as_json(
          only: %i[name brand_name meta_keywords vendor_id vendor_sku stock_status trashbin hide_from_search status count_on_hand created_at updated_at track_inventory],
          include: {
            classifications: { only: %i[taxon_id store_id position] },
            product_properties: { only: %i[value property_id] },
            product_currency_prices: { only: price_fields }
          }
        ).merge(delivery_fields).merge(vendor_fields).merge(searchable_stock_product)
      end

      def self.searche(store, options, p, paginate=false)
        return [] if options[:taxon_id].blank? && options[:vendor_slug].blank? && options[:search_term].blank?

        @query = ESSearch::Product.new(store, options).build_query
        page_products = []
        if paginate
          @page_query = @query.dup
          page_number = (p["page"] || 1).to_i
          per_page= (p["per_page"] || 24).to_i
          @page_query[:size] = per_page
          @page_query[:from] = (page_number - 1) * per_page
          page = Spree::Product.search body: @page_query
          page_products = page.results
        end
        listing = Spree::Product.search body: @query

        [listing.results, page_products]
      end
    end
  end
end
