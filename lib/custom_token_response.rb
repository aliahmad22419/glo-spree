module CustomTokenResponse
  def body
    super.merge(Spree::User.custom_response_variables(@token))
  end
end
