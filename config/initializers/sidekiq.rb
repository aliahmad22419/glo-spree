# From rails 7
# Sidekiq.configure_server do |config|
#   config.redis = { url: 'redis://localhost:6379/1' }
# end

# Sidekiq.configure_client do |config|
#   config.redis = { url: 'redis://localhost:6379/1' }
# end

#From Master
require 'sidekiq'
require 'sidekiq/web'

schedule_file = "config/schedule.yml"

if File.exist?(schedule_file) && Sidekiq.server?
	Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end



# require 'sidekiq/cron/web'
# require 'sidekiq-cron'
#
# redis_url = ENV['REDISCLOUD_URL']
#
#
# Sidekiq::Extensions.enable_delay!
# Sidekiq.configure_server do |config|
# 	config.redis = { url: redis_url }
# 	schedule_file = "config/schedule.yml"
# 	if File.exists?(schedule_file) && Sidekiq.server?
# 		Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
# 	end
# end
#
#
# Sidekiq.configure_client do |config|
# 	config.redis = { url: redis_url }
# end



Sidekiq::Web.use(Rack::Auth::Basic) do |user, password| [user, password] == ["admin", "sasstesting"] end
