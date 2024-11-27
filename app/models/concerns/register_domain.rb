module RegisterDomain
  extend ActiveSupport::Concern

  def stripe_register_domain(stripe_payment_method, domain)
    begin
      Stripe.api_key = stripe_payment_method.preferred_secret_key
      connected_account = self.stripe_connected_account
      apple_pay_domain = Stripe::ApplePayDomain.create({ domain_name: domain },{ stripe_account: connected_account })
    rescue => e
      Rails.logger.error(e.message)
      return nil
    end
    apple_pay_domain
  end

  def register_stripe_apple_pay_domain(store_payment_method)
    stripe_payment_method = Spree::PaymentMethod.find_by('spree_payment_methods.id = ?', store_payment_method[:payment_method_id])
    default_domain = get_url_domain(self.default_url)
    domain = get_url_domain(self.url, self.is_www_domain)
    default_domain_status = stripe_register_domain(stripe_payment_method, default_domain) if default_domain
    domain_status = stripe_register_domain(stripe_payment_method, domain) if domain
    (default_domain_status and domain_status) ? "both" :
      default_domain_status ? "default_domain" :
      domain_status ? "store_domain" : "empty"
  end

  def get_url_domain(url, is_www_domain = false)
    return '' if url.blank?
    is_www_domain ? url.split('www.',2).last.split('/').first : url.split('/').first
  end

end