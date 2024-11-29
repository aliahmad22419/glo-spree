# # From Rails 7
# require_relative "boot"

# require "rails/all"

# # Require the gems listed in Gemfile, including any gems
# # you've limited to :test, :development, or :production.
# Bundler.require(*Rails.groups)

# module GloSpree
#   class Application < Rails::Application
#     # Initialize configuration defaults for originally generated Rails version.
#     config.load_defaults 7.2

#     # Please, add to the `ignore` list any other `lib` subdirectories that do
#     # not contain `.rb` files, or that should not be reloaded or eager loaded.
#     # Common ones are `templates`, `generators`, or `middleware`, for example.
#     config.autoload_lib(ignore: %w[assets tasks])

#     # Configuration for the application, engines, and railties goes here.
#     #
#     # These settings can be overridden in specific environments using the files
#     # in config/environments, which are processed later.
#     #
#     # config.time_zone = "Central Time (US & Canada)"
#     # config.eager_load_paths << Rails.root.join("extras")
#   end
# end





#From Master
require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

Rails::Application.initializer "delete_spree_core_routes", after: "add_routing_paths" do |app|
  routes_paths = app.routes_reloader.paths
  new_spree_frontend_route_path = File.expand_path('../../config/spree_routes_override.rb', __FILE__)

  spree_frontend_route_path = routes_paths.select{ |path| path.include?("spree_frontend") }.first
  spree_wishlist_route_path = routes_paths.select{ |path| path.include?("spree_wishlist") }.first

  spree_admin_routes = routes_paths.select{ |path| path.include?("spree_backend") }.first
  spree_login_routes = routes_paths.select{ |path| path.include?("spree_auth_devise") }.first

  if spree_frontend_route_path.present?
    spree_frontend_route_path_index = routes_paths.index(spree_frontend_route_path)
    routes_paths.delete_at(spree_frontend_route_path_index)
    routes_paths.insert(spree_frontend_route_path_index, new_spree_frontend_route_path)
  end


  if spree_wishlist_route_path.present?
    spree_wishlist_route_path_index = routes_paths.index(spree_wishlist_route_path)
    routes_paths.delete_at(spree_wishlist_route_path_index)
  end

  if spree_admin_routes.present?
    spree_admin_routes_index = routes_paths.index(spree_admin_routes)
    routes_paths.delete_at(spree_admin_routes_index)
  end

  if spree_login_routes.present?
    spree_login_routes_index = routes_paths.index(spree_login_routes)
    routes_paths.delete_at(spree_login_routes_index)
  end
end

module GloSpree
  class Application < Rails::Application

    # load spree::metadata before variant model loading to resolve conflicts
    # between Spree::Metadata and ActiveStorageValidations::Metadata
    require "#{Rails.root}/app/models/concerns/spree/metadata"

    SUPPORTED_MEDIA_TYPES = %w(image/avif image/webp image/jpeg image/jpg image/png image/gif video/mp4 application/octet-stream)

    config.to_prepare do
      #load lib nested directories
      Dir.glob("#{Rails.root}/lib/spree/**/*.rb").each { |file| require(file) }

      # Load application's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Load application's view overrides
      Dir.glob(File.join(File.dirname(__FILE__), "../app/overrides/*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), "../app/controllers/spree/api/v2/storefront/service_login_user/*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), "../app/paginators/spree/shared/paginate.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # Initialize configuration defaults for originally generated Rails version.

    config.load_defaults 7.2
    config.autoload_lib(ignore: %w[assets tasks])
    config.autoload_paths << "#{Rails.root}/lib"

    config.i18n.load_path += Dir[Rails.root.join('config/locales/pdf', '*.{yml}')]

    config.assets.initialize_on_precompile = false


    config.active_storage.variable_content_types = SUPPORTED_MEDIA_TYPES
    config.active_storage.web_image_content_types = SUPPORTED_MEDIA_TYPES

    config.action_dispatch.default_headers = {
        'X-Frame-Options' => 'ALLOWALL'
    }

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins 'https://glo-spree-staging.herokuapp.com', 'https://glo-testing.herokuapp.com', 'https://glo-client.herokuapp.com', 'https://glo-client-staging.herokuapp.com' , 'http://localhost:4200', 'http://192.168.1.40:4200', 'https://glo-ssr-testing.herokuapp.com'
        resource '*', headers: :any, methods: %i(get post put patch delete options head)
      end
    end

    config.active_record.use_yaml_unsafe_load = true
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess, Symbol, BigDecimal, OpenStruct]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
