module TsCurate
  class TsClientService
    attr_accessor :user, :client, :ts_url, :ts_response, :ts_client, :options

    def initialize(user, options)
      @user = user
      @client = user.client
      @options = options
      @ts_url = options[:ts_url]
    end

    def ts_user_client
      if options[:email].blank?
        client.update_columns(ts_email: '', ts_password: '', ts_url: '')
        return OpenStruct.new({ success: true, message: '', error: 'Ts Client changes saved successfully' })
      end

      return OpenStruct.new({ success: false, message: '', error: 'Ts Url must be present' }) if ts_url.blank?
      
      @ts_response = HTTParty.post("#{ts_url}/api/v1/clients/create_or_update_client", body: ts_client_params)
      
      client.update_columns(ts_email: options[:email], ts_password: options[:password], ts_url: ts_url) if ts_response.success?
      parsed_response
    end

    private

    def parsed_response
      return (OpenStruct.new({ success: ts_response.success?, message: ts_response['message'], error: ts_response['error'] }) rescue "Something went wrong")
    end

    def ts_client_params
      return ts_params = {
        client: {
          name: options[:name] || client.name,
          address: options[:address] || "PK",
          contact: options[:contact] || "123456",
          origin: options[:origin] || "",
          users_attributes: [{
            email: options[:email],
            password: options[:password],
            password_confirmation: options[:password],
            enable_request_id: options[:enable_request_id]
          }]
        }
      }
    end
  end
end
