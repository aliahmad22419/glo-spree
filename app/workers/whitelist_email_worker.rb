class WhitelistEmailWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'whitelist_email_queue'

  def perform
    pending_emails = Spree::WhitelistEmail.where(status: [:pending.to_s, :failed.to_s])
    ses_client = Aws::SES::Client.new()

    pending_emails.find_each do |whitelist_email|
      resp = ses_client.get_identity_verification_attributes(identities: [whitelist_email.email])
      next unless resp.present? && resp.verification_attributes[whitelist_email.email]

      verification_status = resp.verification_attributes[whitelist_email.email].verification_status.to_sym
      db_status = if verification_status == :Success
        :verified.to_s
      elsif verification_status == :Pending
        :pending.to_s
      elsif verification_status == :Failed
        :failed.to_s
      end

      whitelist_email.update_column(:status, db_status)
    end
  end
end