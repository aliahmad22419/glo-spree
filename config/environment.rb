# From Rails 7
# # Load the Rails application.
# require_relative "application"

# # Initialize the Rails application.
# Rails.application.initialize!


#From Master
# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

GloSpree::Application.default_url_options = GloSpree::Application.config.action_mailer.default_url_options
