class SnsNotification

  def initialize(email_data,message, topic_arn)
    @client = Aws::SNS::Client.new()
    @topic_arn = topic_arn
    @message = message
    @message_attributes = {
        data: {
          data_type: "String",
          string_value: {
            from: [email_data[:from]],
            cc: [],
            bcc: [],
            to: [email_data[:to]],
            template: email_data[:template],
            template_data: email_data[:template_data]
          }.to_json
        }
    }  
  end

  def publish
    begin
      @client.publish(
        topic_arn: @topic_arn,
        message_attributes: @message_attributes,
        message: @message
      )
    rescue StandardError => e
      Rails.logger.error("SNS notification failed to send with message: #{e.message}") and return
    end
    Rails.logger.info("SNS notification sent.")
  end

end
