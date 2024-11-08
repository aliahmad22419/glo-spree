module Spree
  module Api
    module V2
      module CollectionOptionsHelpers
        def collection_links(collection)
          {
            self: request.original_url,
            next: pagination_url(next_page(collection) || total_pages(collection)),
            prev: pagination_url(prev_page(collection) || 1),
            last: pagination_url(total_pages(collection)),
            first: pagination_url(1)
          }
        end

        def collection_meta(collection)
          {
            count: current_count(collection),
            total_count: total_count(collection),
            total_pages: total_pages(collection)
          }
        end

        # leaving this method in public scope so it's still possible to modify
        # those params to support non-standard non-JSON API parameters
        def collection_permitted_params
          params.permit(:format, :page, :per_page, :sort, :include, :fields, filter: {})
        end

        private

        def next_page(collection)
          collection = [] if collection.blank?
          collection.next_page rescue collection.page(params['page']).next_page rescue nil
        end

        def prev_page(collection)
          collection = [] if collection.blank?
          collection.prev_page rescue collection.page(params['page']).prev_page rescue nil
        end

        def total_pages(collection)
          collection = [] if collection.blank?
          return 1 if params['per_page'].blank? || params['page'].blank?
          pages = (collection.size / (params['per_page'] || collection.size).to_i).to_i
          pages += 1 if (collection.size % (params['per_page'] || collection.size).to_i) != 0
          collection.total_pages rescue pages
        end

        def total_count(collection)
          collection = [] if collection.blank?
          collection.total_count rescue collection.size
        end

        def current_count(collection)
          collection = [] if collection.blank?
          return collection.size if params['per_page'].blank? || params['page'].blank?
          return 0 if (params['page'] > total_pages(collection).to_s rescue true)
          return (collection.size % (params['per_page'] || 1).to_i) if params['page'].eql?(total_pages(collection).to_s) && (collection.size % (params['per_page'] || 1).to_i) != 0
          (params['per_page'] || 1).to_i
        end

        def pagination_url(page)
          url_for(collection_permitted_params.merge(page: page))
        end

        def collection_options(collection)
          collection = [] if collection.blank?
          {
            links: collection_links(collection),
            meta: collection_meta(collection),
            include: resource_includes,
            fields: sparse_fields
          }
        end
      end
    end
  end
end
