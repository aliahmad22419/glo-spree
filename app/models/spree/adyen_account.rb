module Spree
  class AdyenAccount < Spree::Base
    belongs_to :vendor, class_name: "Spree::Vendor"

    def request_holder_account(account_details)
      pm = self.vendor.client.payment_methods.find_by_type("Spree::Gateway::AdyenGateway") rescue nil
      return unless pm.present?
      adyen = Adyen::Client.new
      adyen.env = pm.preferred_server.to_sym
      adyen.api_key = pm.preferred_api_key

      response = adyen.marketpay.account.create_account_holder(account_details).response

      if response['invalidFields'].blank? && response['accountCode'].present?
        self.account_code = response['accountCode']
        self.account_holder_code = response['accountHolderCode']
        self.save
        self.onboarding_url
      elsif response['invalidFields'].present?
        self.errors.add(:base, response['invalidFields'][0]['ErrorFieldType']['fieldType']['fieldName'] + " " + response['invalidFields'][0]['ErrorFieldType']['errorDescription'])
      elsif response['errorCode'].present?
        self.errors.add(:base, response['message'])
      end
    end

    def onboarding_url
      pm = self.vendor.client.payment_methods.find_by_type("Spree::Gateway::AdyenGateway") rescue nil
      return unless pm.present?
      adyen = Adyen::Client.new
      adyen.env = pm.preferred_server.to_sym
      adyen.api_key = pm.preferred_api_key

      response = adyen.marketpay.hop.get_onboarding_url({ "accountHolderCode": self.account_holder_code, "returnUrl": "#{ENV['VENDOR_MANAGEMENT_URL']}/vendor/settings/adyen-account" })
      response = response.response

      if response['invalidFields'].blank? && response['resultCode'].eql?("Success")
        response['redirectUrl']
      elsif response['invalidFields'].present?
        self.errors.add(:base, response['invalidFields'][0]['ErrorFieldType']['errorDescription'])
      elsif response['errorCode'].present?
        self.errors.add(:base, response['message'])
      end
    end

    def get_account_holder
      pm = self.vendor.client.payment_methods.find_by_type("Spree::Gateway::AdyenGateway") rescue nil
      return unless pm.present?
      adyen = Adyen::Client.new
      adyen.env = pm.preferred_server.to_sym
      adyen.api_key = pm.preferred_api_key

      response = adyen.marketpay.account.get_account_holder({ "accountHolderCode": self.account_holder_code, "showDetails": true })
      response = response.response
    end
  end
end
