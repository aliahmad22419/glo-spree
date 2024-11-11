source "https://rubygems.org"

ruby '3.3.2'
# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"
# Use SCSS for stylesheets
gem "sass-rails", "~> 6.0"
gem "sass", "~> 3.7", ">= 3.7.4"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
# Adding gems from gl0-spree:
gem "psych", "< 4"
gem "spree", "4.10.1"
# gem "spree_auth_devise", "~> 4.6.3"
gem "acts_as_list", "~> 1.2.3"
gem "spree_gateway", "4.1.3", github: "zaintechsembly/spree_gateway", branch: "3-10-stable"
# gem "spree_multi_vendor"
# gem "spree_multi_domain", "~>3.3.2", github: "zainrafique/spree-multi-domain"
gem "spree_sitemap", github: "spree-contrib/spree_sitemap"
gem "ransack", "4.1.1"
gem "rack-cors", require: "rack/cors"
gem "dotenv-rails"
gem "aasm"
# gem "spree_reviews", github: "spree-contrib/spree_reviews"
# gem "spree_related_products", path: "../spree_related_products"
gem "spree_api_v1"
# gem "spree_gift_card",  path: "../spree_gift_card"
gem "spree_print_invoice", github: "aliahmad22419/spree_print_invoice", branch: "master"
# gem "spree_multi_client",  path: "../spree_multi_client"
# gem "spree_mailchimp_ecommerce", "~>1.5.1", github: "zaintechsembly/spree_mailchimp_ecommerce"
gem "aws-sdk-s3", require: false
gem "searchkick", "5.3.1"
gem "stripe"
gem "adyen-ruby-api-library", "4.2"
gem "active_model_otp"
gem "prawn-rtl-support", "~> 0.1.7"
gem "prawn-html"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "soap4r-ng", :git=>"https://github.com/rubyjedi/soap4r.git", :branch=>"master"
gem "sidekiq"
gem "sidekiq-cron", "~> 1.1"
gem "httparty"
gem "foreman"
gem "aws-sdk-sqs"
gem "aws-sdk-acm"
gem "bootstrap"
gem "aws-sdk-ses"
gem "aws-sdk-sns"
gem "passbook"
gem "hiredis"
gem "redis"
gem "gibbon"
gem "acts-as-taggable-on"
gem "deface"
gem "excon"
gem "fog-aws"
gem "asset_sync"
gem "rollbar"
gem "exception_notification"
# gem "spree_backend", path: "../spree_backend"
# gem "spree_frontend"
gem "elasticsearch"
gem "net-sftp"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "letter_opener"
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "listen"
  gem "pry-rails"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.1.0"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara", ">= 2.15"
  gem "selenium-webdriver", "4.0.0"
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem "chromedriver-helper"
end
