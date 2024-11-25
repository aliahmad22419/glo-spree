class TokenController < Doorkeeper::TokensController

	# Overriding create action
	# POST /oauth/token
  def create
    response = strategy.authorize
    body = response.body
		message, version_reponse = verify_mobile_app_version
		unless version_reponse
			return render json: {message: message}, status: :unprocessable_entity
		end
		
    if response.status == :ok
      # Return user id
      body[:id] = response.token.resource_owner_id unless nil
			body[:message] = message
    end

    self.headers.merge! response.headers
    self.response_body = body.to_json
    self.status        = response.status

  rescue Doorkeeper::Errors::DoorkeeperError => e
    handle_token_exception e
  end

	private
		def verify_mobile_app_version
			compactable_version_hash = {
				"current_version": '2.2.0',
				"support_legacy_version": '2.0.0'
			}
			if (request.headers['X-App-Version'])
				requested_app_version = get_version_number(request.headers['X-App-Version'])
				support_legacy_version = get_version_number(compactable_version_hash[:support_legacy_version])
				current_version = get_version_number(compactable_version_hash[:current_version])
				return "Unable to Support this version. Please, update your app", false if (requested_app_version < support_legacy_version) 
				return "Please update your app", true if ((requested_app_version < current_version) && (requested_app_version >= support_legacy_version ))
				return nil,true if (requested_app_version >= current_version)
			end
			return "Please update your app", true
		end

		def get_version_number(version) 
			return version&.remove('.')&.to_i
		end

end
