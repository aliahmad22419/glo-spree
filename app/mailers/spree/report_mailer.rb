module Spree
  class ReportMailer < BaseMailer

    def send_report_to_recipient report
      email = report.email
      @email = email
      @store = report.store
      client = report&.client
      @url = ApplicationRecord.active_storge_url(report.attachment)
      mail(to: email, from: "#{client&.name} <#{client&.users&.first&.email}>", cc: cc_store_recipients(@store), subject: "You have a new message")
    end

  end
end
