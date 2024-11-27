
module DoorkeeperErrorResponseDecorator

  def status
    if [:invalid_client, :invalid_grant].include? name
      :unauthorized
    else
      :bad_request
    end
  end

end
