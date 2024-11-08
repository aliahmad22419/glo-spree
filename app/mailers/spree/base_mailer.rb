module Spree
  class BaseMailer < ActionMailer::Base

    def money(amount, currency = Spree::Config[:currency])
      Spree::Money.new(amount, currency: currency).to_s
    end
    helper_method :money
    # add_template_helper(Spree::Mailer::EmailHelper)

    def frontend_available?
      Spree::Core::Engine.frontend_available?
    end
    helper_method :frontend_available?

    def str_to_a email_addresses
      email_addresses&.split(',')&.map(&:strip) || []
    end
    
    def cc_to(cc_emails = [])
      cc_emails << (@store.client.users.with_role('client').email rescue nil)
      cc_emails.compact.uniq
    end

    def email_from_store
      (@store&.mail_from_address || Spree::Store.current.mail_from_address)
    end

    def cc_store_recipients(store)
      str_to_a(store&.recipient_emails)
    end

    def bcc_to(bcc_emails = [])
      bcc_emails += (str_to_a @store&.bcc_emails)
      bcc_emails.uniq
    end

    def mail(headers = {}, &block)
      headers[:cc].present? ? (headers[:cc] = cc_to(headers[:cc])) : headers.merge!({ cc: cc_to })
      headers[:bcc].present? ? (headers[:bcc] = bcc_to(headers[:bcc])) : headers.merge!({ bcc: bcc_to })
      headers[:from].present? ? (headers[:from] = headers[:from]) : headers.merge!({ from: email_from_store })
      ensure_default_action_mailer_url_host
      super if Spree::Config[:send_core_emails]
    end

    private

    # this ensures that ActionMailer::Base.default_url_options[:host] is always set
    # this is only a fail-safe solution if developer didn't set this in environment files
    # http://guides.rubyonrails.org/action_mailer_basics.html#generating-urls-in-action-mailer-views
    def ensure_default_action_mailer_url_host
      ActionMailer::Base.default_url_options ||= {}
      ActionMailer::Base.default_url_options[:host] ||= Spree::Store.current.url
    end
  end
end
