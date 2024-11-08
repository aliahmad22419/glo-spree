module Spree
	class SnsErrorLogger
		prepend Spree::ServiceModule::Base

		def call(options:)
			run :send_sns_error_notification
		end
		
		private
		
		def send_sns_error_notification(options:)
			begin
				Aws::SNS::Client.new().publish(
					topic_arn: (options[:logger_sns_topic_arn] || ENV['ERROR_LOGGER_SNS_ARN']),
					message_attributes: options[:message_attributes],
					message: options[:message]
				)
				success(true)
			rescue Exception => e
				Rails.logger.error(e.message)
				failure({error: e.message})
			end
		end
	end
end
