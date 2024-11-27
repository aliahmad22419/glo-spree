module Spree
  class WhitelistEmail < Spree::Base
    enum status: { pending: 0, verified: 1, failed: 2 }
    enum identity_type: { email: 0, domain: 1 }
    belongs_to :client, class_name: 'Spree::Client'
    after_create :send_verification
    after_destroy :remove_verified_email
    validate :availability, on: :create
    validates :email, presence: true, if: :email?
    validates :recipient_email, :domain, presence: true, if: :domain?
    self.whitelisted_ransackable_attributes = %w[email identity_type domain]

    def send_verification
      client = Aws::SES::Client.new()
      if identity_type == 'domain'
        resp = client.verify_domain_dkim({ domain: domain })
        if resp.present?
          self.update_columns(verification_sent: true, meta: { dkim_tokens: resp.dkim_tokens })
          Spree::SES::Mailer.dkim_instructions(self)
        end
      else
        self.update_column(:verification_sent, true) if client.verify_email_identity({ email_address: self.email })
      end
    end

    def retry_domain_verification
      client = Aws::SES::Client.new()
      resp = client.verify_domain_dkim({ domain: domain })
      Spree::SES::Mailer.dkim_instructions(self) if resp.present?
    end

    def resend_verification
      client = Aws::SES::Client.new()
      client.verify_email_identity({ email_address: self.email })
    end

    def remove_verified_email
      client = Aws::SES::Client.new()
      identity = identity_type.eql?('domain') ? domain : email
      client.delete_identity(identity: identity)
    end

    private

    def availability
      if identity_type.eql?(:email.to_s)
        if self.client.whitelist_emails.find_by(email: email, identity_type: :email.to_s)
          errors.add(:email, "already taken")
        elsif Spree::WhitelistEmail.find_by(email: email, identity_type: :email.to_s)
          errors.add(:email, "is not available")
        end
      else
        if self.client.whitelist_emails.find_by(domain: domain, identity_type: :domain.to_s)
          errors.add(:domain, "already taken")
        elsif Spree::WhitelistEmail.find_by(domain: domain, identity_type: :domain.to_s)
          errors.add(:domain, "is not available")
        end
      end
    end
  end
end
