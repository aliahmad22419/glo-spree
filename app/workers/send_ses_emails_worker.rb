class SendSesEmailsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'send_ses_emails'

  def perform template, data, to_addresses,from_address, cc_addresses = [], bcc_addresses = []
    client = Aws::SES::Client.new()
    resp = client.send_templated_email({
                                           source: from_address, # required
                                           destination: { # required
                                                          to_addresses: to_addresses,
                                                          cc_addresses: cc_addresses,
                                                          bcc_addresses: bcc_addresses,
                                           },
                                           template: template, # required
                                           template_data: data.to_json, # required
                                       })
  end
end