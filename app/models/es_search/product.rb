module ESSearch
  class Product

    def initialize(store, options = {})
      @sort = options[:sort]
      @set_filters = lambda do |context_type, filter|
        @search_definition[:query][:bool][context_type].push filter
      end
      @set_sorter = lambda { |sort| @search_definition[:sort] = [sort] }
      @price_filters = options[:price_filter_values]
      @property_filters = options[:property_filters]
      @term = options[:search_term]
      @active_vendor_ids = options[:active_vendor_ids]
      @vendor_slug = options[:vendor_slug]
      @taxon_id = (options[:taxon_id].is_a?(Array) ? options[:taxon_id][0] : options[:taxon_id])
      @store_id = options[:store_id]
      @default_currency = options[:default_currency]
      @store = store
    end

    def query
      initial_filters = [
        { term:  { trashbin: false }},
        { term:  { stock_status: true }},
        { term:  { status: 'active' }},
        { term:  { hide_from_search: false }},
        { term:  { searchable_stock_product: true }},
        { bool:  { should: [{ term: { track_inventory: false }},{ range: { count_on_hand: {gt: 0}}}] } }
      ]

      initial_musts = [
        {
          nested: {
            path: "classifications",
            query: { bool: { must: [{ match: { "classifications.store_id": store_id } }] } }
          }
        }
      ]

      @search_definition ||= {
        size: 10000,
        query: { bool: { must: initial_musts, should: [], filter: initial_filters } },
        sort: []
      }
    end

    def build_query
      query
      price_filter if price_filters.present?
      set_filters.call(:filter, { terms: { vendor_id: (active_vendor_ids || []) } }) unless vendor_slug.present?
      if term.present?
        # @search_definition[:query][:bool][:minimum_should_match] = 1
        search_term
        search_fields = %w[name meta_keywords vendor_name vendor_sku]
        search_fields.push("brand_name") if @store.show_brand_name
        match_term = { query_string: { query: term, fields: search_fields } }
        set_filters.call(:must, match_term)
        # match_term = { query_string: { query: term, fields: %w[vendor_name], boost: 4 } }
        # set_filters.call(:should, match_term)
        # prioritize_phrase_words
        # match_term = { query_string: { query: term, fields: %w[name], boost: 3 } }
        # set_filters.call(:should, match_term)
        # if @store.show_brand_name
        #   match_term = { query_string: { query: term, fields: %w[brand_name], boost: 3 } }
        #   set_filters.call(:should, match_term)
        # end
        # match_term = { query_string: { query: term, fields: %w[vendor_sku], boost: 2 } }
        # set_filters.call(:should, match_term)
        # match_term = { query_string: { query: term, fields: %w[meta_keywords] } }
        # set_filters.call(:should, match_term)
      end
      set_filters.call(:must, { match: { vendor_slug: vendor_slug } }) if vendor_slug.present?
      category_filter if taxon_id.present?
      filter_properties if property_filters.present?
      sort_by
      @search_definition
    end

    private

    attr_reader :term, :active_vendor_ids, :vendor_slug, :taxon_id, :store_id, :store, :default_currency,
                :search_definition, :sort, :set_filters, :price_filters, :set_sorter, :property_filters

    def search_term
      special_chars = %w[( ) [ ] { } > < , . ? / ~ ` ˜ | : ; ' " + = - _ § ± ! @ # $ % ^ & *]
      rules = special_chars.each_with_object({}) { |elem, hsh| hsh[elem] = "\\#{elem}" }

      reg = Regexp.new(rules.keys.map { |x| Regexp.escape(x) }.join('|'))
      @term = @term.gsub(reg, rules)
      @term = @term.split(' ').map{ |s| "*#{s}*" }.join(' ')
    end

    def filter_properties
      property_filters.each do |property_id, filter_values|
        property = if property_id == "de"
          country = Spree::Country.find_by(id: store&.country_ids[0])
          zone = country.zones.first&.name if country.present?
          zone ||= "unknown"
          { terms: { "calculated_days_to_#{zone.downcase}": filter_values } }
        else
          {
            nested: {
              path: 'product_properties',
              query: {
                bool: {
                  must: [
                    { match: { "product_properties.property_id": property_id } },
                    { terms: { "product_properties.value": filter_values } }
        					]
                }
              }
            }
          }
        end
        set_filters.call(:must, property)
      end
    end

    def min_price
      price_filters[0] rescue 0
    end

    def max_price
      price_filters[1] rescue nil # Float::INFINITY
    end

    def price_in_currency
      price_filters[2] rescue default_currency
    end

    def desc_order
      @desc_order ||= String(sort)[0] == '-'
    end

    def order_direction
      desc_order ? :desc : :asc
    end

    def sort_field
      @sort_field ||= desc_order ? sort[1..-1] : sort
    end

    def category_filter
      classify = {
        nested: {
          path: 'classifications',
          query: { bool: { must: [{ match: { "classifications.taxon_id": taxon_id } }] } }
        }
      }
      set_filters.call(:must, classify)
      # set_filters.call(:filter, { terms: { vendor_id: active_vendor_ids } }) if active_vendor_ids.present?
    end

    def price_filter
        have_price_between = {
          nested: {
            path: "product_currency_prices",
            query: {
              bool: {
                must: [
                  { match: { 'product_currency_prices.to_currency': price_in_currency } },
                  {
                    script: {
                      script: {
                        inline: """
                                def price = -1;
                                if (doc['product_currency_prices.local_store_ids'].size() != 0 && doc['product_currency_prices.local_store_ids'].value.contains(params.store_id)) {
                                  price = doc['product_currency_prices.local_area_price'].value;
                                } else {
                                  price = doc['product_currency_prices.wide_area_price'].value;
                                }
                                if (doc['product_currency_prices.taxes'].size() != 0){
                                  for(int i=0; i < doc['product_currency_prices.taxes'].length; i++){
                                    def tax_str = doc['product_currency_prices.taxes'][i];
                                    if(tax_str.startsWith('store'+params.store_id)){
                                      price = price * (1 + Float.parseFloat(tax_str.splitOnToken(':')[1].splitOnToken('-')[1]));
                                    }
                                  }
                                }
                                price >= params.min_price && price <= params.max_price;
                                """,
                        lang: "painless",
                        params: {
                          currency: price_in_currency,
                          store_id: store_id.to_s,
                          min_price: min_price,
                          max_price: (max_price || Float::INFINITY)
                        }
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      set_filters.call(:must, have_price_between)
    end

    def price_sort
        price_sorter = {
          _script: {
            order: order_direction,
            nested: {
              path: 'product_currency_prices',
              filter: { match: { 'product_currency_prices.to_currency': price_in_currency } }
            },
            type: "number",
            script: {
              source: """
                      def price = -1;
                      if (doc['product_currency_prices.local_store_ids'].size() != 0 && doc['product_currency_prices.local_store_ids'].value.contains(params.store_id)) {
                        price = doc['product_currency_prices.local_area_price'].value;
                      } else {
                        price = doc['product_currency_prices.wide_area_price'].value;
                      }
                      if (doc['product_currency_prices.taxes'].size() != 0){
                        for(int i=0; i < doc['product_currency_prices.taxes'].length; i++){
                          def tax_str = doc['product_currency_prices.taxes'][i];
                          if(tax_str.startsWith('store'+params.store_id)){
                            price = price * (1 + Float.parseFloat(tax_str.splitOnToken(':')[1].splitOnToken('-')[1]));
                          }
                        }
                      }
                      price;
                      """,
              params: {
                currency: price_in_currency,
                store_id: store_id.to_s
              }
            }
          }
        }
      set_sorter.call(price_sorter)
    end

    def best_seller_sort
      seller_filters = { bool: { must: [{ match: { 'classifications.store_id': store_id } }] } }
      seller_filters[:bool][:must].push({ match: { 'classifications.taxon_id': taxon_id } }) if taxon_id.present?

      seller_sort = {
        'classifications.position': {
          order: :asc,
          nested: {
            path: 'classifications',
            filter: seller_filters
          }
        }
      }
      seller_sort[:'classifications.position'][:mode] = :min unless taxon_id.present?
      set_sorter.call(seller_sort)
    end

    def name_sort
      set_sorter.call({ name: { order: order_direction } })
    end

    def new_arrivals_sort?
      set_sorter.call({ created_at: { order: order_direction } })
    end

    def newly_updated_sort?
      set_sorter.call({ updated_at: { order: order_direction } })
    end

    def sort_by
      price_sort if price?
      name_sort if name?
      best_seller_sort if best_seller?
      new_arrivals_sort? if created_at?
      newly_updated_sort? if updated_at?
    end

    def best_seller?
      sort_field == 'best_seller'
    end

    def price?
      sort_field == 'price'
    end

    def name?
      sort_field == 'name'
    end

    def created_at?
      sort_field == 'created_at'
    end

    def updated_at?
      sort_field == 'updated_at'
    end
  end
end
