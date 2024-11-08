module Spree::SES
  class Mailer
    class << self
      def invite_vendor(name_or_email, to, from, store_name)
        from = nil
        ses_template = Spree::EmailTemplate.find_by(email_type: "spree_vendor_invite_#{ENV['SES_ENV']}")
        encoded_param_value = URI.encode_www_form_component(to)
        data = {name: name_or_email, link: ENV['VENDOR_MANAGEMENT_URL'] + "/vendor-onboarding?email=#{encoded_param_value}", store_name: store_name}
        Rails.logger.error("No email template found for spree_vendor_invite_#{ENV['SES_ENV']}") and return unless ses_template.present?

        send_email(ses_template, data, from, [to])
      end

      private

      def send_email(template, data, from_address, to_addresses, cc_addresses = [], bcc_addresses = [])
        from_address ||= 'noreply@techsembly.com'
        client = Aws::SES::Client.new()
        client.send_templated_email({
            source: from_address,
            destination: { to_addresses: to_addresses, cc_addresses: cc_addresses, bcc_addresses: bcc_addresses },
            template: template.name,
            template_data: data.to_json,
        })
      end
    end
  end
end