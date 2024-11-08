module Spree
  class UpdateOrderSpreadSheet
    prepend Spree::ServiceModule::Base
  
    def initialize(order_id,queue_name,message_body)
      @order = Spree::Order.find(order_id)
      @queue_name = queue_name
      @message_body = message_body
    end
  
    def update_sheet
      sqs = Aws::SQS::Client.new()
      sqs.send_message({  
        queue_url: @queue_name,
        message_body: @message_body,
        message_attributes: {
          "order_spreadsheet_data" => {
            string_value: "#{(@order.get_order_spreadsheet_data).to_json}",
            data_type: "String"
          }
        }
      })
    end
  end
end
  