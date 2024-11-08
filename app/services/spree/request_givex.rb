module Spree
  module RequestGivex

    def handle_request(primary_url, body, secondary_url)
      primary_url, secondary_url = secondary_url, nil if primary_url.blank?

      response = request_givex(primary_url, body, secondary_url)
      response = request_givex(secondary_url, body) if (500..599).include?(response&.code) && secondary_url.present?
      response
    end

    private
    def request_givex(primary_url, body, secondary_url = nil)
      HTTParty.post(primary_url, body: body)
    rescue => exception
      raise exception unless secondary_url
      HTTParty.post(secondary_url, body: body)
    end

  end
end
