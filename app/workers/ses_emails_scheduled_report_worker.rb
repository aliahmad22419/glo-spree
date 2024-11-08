class SesEmailsScheduledReportWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'scheduled_reports_ses_queue'

    def perform(scheduled_report_id)
        report = ScheduledReport.find(scheduled_report_id)
        data = { report_url: report.report_link }

        ses_template = Spree::EmailTemplate.find_by(client_id: report.client_obj.id, email_type: report.report_type)
        Rails.logger.error("No email template found") and return unless ses_template.present?

        to_addresses = report.preferences['to_email_addresses'].split(',').map(&:strip) rescue []
        cc_addresses = report.preferences['cc_email_addresses'].split(',').map(&:strip) rescue []
        from_address = report.client_obj.reporting_from_email_address.strip

        send_emails(ses_template, data, to_addresses, cc_addresses, from_address)
    end

    private

    def send_emails template, data, to_addresses, cc_addresses, from_address
        client = Aws::SES::Client.new()
        resp = client.send_templated_email({
            source: from_address, # required
            destination: { # required
                            to_addresses: to_addresses,
                            cc_addresses: cc_addresses
            },
            template: template.name, # required
            template_data: data.to_json, # required
        })
    end
end
