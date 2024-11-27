module Spree
  class GivexCard < Spree::Base
    has_one_attached :pk_pass
    has_many :log_entries, as: :source
    has_many :bookkeeping_documents, as: :printable, dependent: :destroy
    has_many :history_logs, :as => :loggable
    include GiftCardConcern
    belongs_to :user, :class_name => 'Spree::User'
    belongs_to :order, :class_name => 'Spree::Order'
    belongs_to :line_item, :class_name => 'Spree::LineItem'
    before_create :set_slug
    enum send_gift_card_via: { sms: 0, email: 1, both: 2 }
    enum status: { pending: 0, active: 1, canceled: 2 }
    enum request_state: { processable: 0, processing: 1, processed: 2 }

    belongs_to :store, class_name: 'Spree::Store'
    belongs_to :client, class_name: "Spree::Client"

    scope :is_generated, -> { where(card_generated: true) }
    scope :not_generated, -> { where(card_generated: false) }
    scope :bonus_cards, -> { where(bonus: true) }

    self.default_ransackable_attributes = %w[givex_number customer_email invoice_id created_at expiry_date active_card]
    self.whitelisted_ransackable_associations = %w[store]

    def self.ransackable_scopes(auth_object = nil)
      %i(expiry_date_from_scope expiry_date_to_scope created_at_from_scope created_at_to_scope )
    end

    def self.expiry_date_from_scope(date)
      where("expiry_date >= ?", DateTime.parse(date).beginning_of_day)
    end

    def self.expiry_date_to_scope(date)
      where("expiry_date <= ?", DateTime.parse(date).end_of_day)
    end

    def self.created_at_from_scope(date)
      where("spree_givex_cards.created_at >= ?", DateTime.parse(date).beginning_of_day)
    end

    def self.created_at_to_scope(date)
      where("spree_givex_cards.created_at <= ?", DateTime.parse(date).end_of_day)
    end
    # after_create :send_email_to_customer, :send_confirmation_to_purchaser

    def send_email_to_customer
      Spree::GeneralMailer.send_givex_cadentials_to_customer(self).deliver_now
    end

    def send_confirmation_to_purchaser
      # Spree::GeneralMailer.send_confirmation_to_purchaser(self).deliver_now
    end

    def self.generete_and_send_email(result, params, current_client_id, current_user_id)
      response = result.value
      expiry_date = Date.parse(response["result"][5]) unless response["result"][5] == "None"
      givex_card = Spree::GivexCard.create(givex_response: result.to_json,customer_email: params[:customer_email], currency: params[:currency],
                              customer_first_name: params[:customer_first_name], customer_last_name: params[:customer_last_name],
                              givex_number: response["result"][3], givex_transaction_reference: response["result"][2], balance: response["result"][4],
                              expiry_date: expiry_date, receipt_message: response["result"][6], comments: params[:comments],
                              card_generated: true, invoice_id: params[:invoice_id], from_email: params[:from_email], store_id: params[:store_id], status: 'active',
                              client_id: current_client_id, send_gift_card_via: params[:send_gift_card_via], receipient_phone_number: params[:receipient_phone_number], user_id: current_user_id)
      givex_card.check_balance(params[:store_id])
      if givex_card.send_gift_card_via.eql?("sms") || givex_card.send_gift_card_via.eql?("both")
        SmsWorker.perform_async(givex_card.store.id, givex_card.receipient_phone_number, "Spree::GivexCard", givex_card.slug)
      end
      if givex_card.send_gift_card_via.eql?("email") || givex_card.send_gift_card_via.eql?("both")
        SesEmailsDataWorker.perform_async(givex_card.id, "digital_givex_card_recipient")
      end
    end

    def generate_givex_data
      recipient_name = "#{customer_first_name} #{customer_last_name}"
      givex_pin = givex_transaction_reference&.split(':')[1] || givex_transaction_reference
      sender_email = user&.email
      sender_name = bonus? ? "#{order&.bill_address&.full_username}" : line_item&.sender_name
      data = {image_url: line_item&.voucher_image_url, product_title: line_item&.product&.name, balance: balance? ? ("%.2f" % balance)&.to_s : "", balance_amount: balance? ? ("%.2f" % balance)&.to_s : "",
              gift_message: line_item&.message, recipient_name: recipient_name, givx_number: givex_number,
              givex_pin: givex_pin, sender_email: sender_email, vendor_name: line_item&.product&.vendor&.name,
              receipient_first_name: customer_first_name&.to_s, receipient_last_name: customer_last_name&.to_s,
              gift_sender_name: line_item&.sender_name, receipient_email: line_item&.receipient_email,
              store_url: "https://#{store&.url}", currency: order&.currency, currency_symbol: Spree::Money.new(order&.currency)&.currency&.symbol, line_items: (self.line_item&.ses_email_data || []),
              sender_name:  sender_name, recipient_email_link: line_item&.product&.recipient_email_link, sms_link: "https://#{store&.url}/givex/#{slug}", bonus: bonus,
              pk_pass_attached: self.pk_pass.attached?, pk_pass_url: self.apple_pass_download_url, from_name_first_name: order&.bill_address&.firstname,
              from_name_last_name:  order&.bill_address&.lastname, brand_name: line_item&.product&.brand_name, terms_and_conditions:line_item&.product&.preferred_terms_and_conditions,
              order: self&.order&.attributes, order_number: self&.order&.number, language: (store&.preferred_default_language || 'en'), pdf_url: self.pdf_url, iso_code: self.iso_code }
      convert_nil_to_string(data)
    end

    def generate_card
      processing!

      store = order.store
      product = line_item.product
      prices = line_item.price_values(order.currency)
      amount = prices[:sub_total].to_f
      first_name = line_item.receipient_first_name
      last_name = line_item.receipient_last_name
      phone_number = line_item.receipient_phone_number
      email = line_item.receipient_email

      if bonus
        amount = (amount * store.preferred_bonus_percentage.to_i) / 100
        billing_address = order&.billing_address
        first_name = billing_address&.firstname
        last_name = billing_address&.lastname
        phone_number = line_item.receipient_phone_number.present? ? billing_address&.phone : nil
        email = order.email
      end

      options = { id: line_item.id.to_s + id.to_s, amount: amount, store_id: store.id, comments: order&.number }
      result = Spree::RegisterGivex.call(options: options)
      update_column(:givex_response, result.to_json)

      if result && result.value['result'].count > 5
        update_columns(card_generated: true, request_state: :processed)

        response = result.value
        expiry_date = Date.parse(response['result'][5]) unless response['result'][5] == 'None'
        update({ transaction_code: line_item.id, customer_email: email, customer_first_name: first_name,
                 customer_last_name: last_name, receipient_phone_number: phone_number, user_id: order&.user&.id,
                 line_item_id: line_item.id, order_id: order.id, store_id: store.id,
                 send_gift_card_via: (product&.send_gift_card_via || "email"), client_id: store&.client&.id,
                 expiry_date: expiry_date, givex_number: response['result'][3],
                 givex_transaction_reference: response['result'][2], balance: response['result'][4],
                 receipt_message: response['result'][6], comments: response['result'][7], status: 'active' })

        ApplePass.new(self).send(:attach)
        check_balance(store.id)
        post_generation_emails
      else
        processable!
        log_entries.create(details: result.to_json)
      end
    rescue => exception
      processable!
      log_entries.create(details: exception.message)
    end

    def set_slug
      loop do
        self.slug = SecureRandom.uuid
        break unless Spree::GivexCard.where(slug: slug).exists?
      end
    end

    def convert_nil_to_string(h)
      h.each_with_object({}) { |(k,v),g|
        g[k] = (Hash === v) ?  convert_nil_to_string(v) : v.nil? ? '' : v }
    end

    def self.active_card(givex_card_number, response, store_id, current_client_id, amount, currency, current_user_id)
      card = Spree::GivexCard.find_by(givex_number: givex_card_number)
      if card
        card.update(status: 'active') unless card.active?
      else
        data = {
            givex_number: givex_card_number, active_card: true,
            givex_response: response, store_id: store_id, client_id: current_client_id,
            balance: amount, currency: currency, iso_code: response["result"][6],
            user_id: current_user_id,
            status: 'active'
        }
        record = Spree::GivexCard.new(data)
        record.save
      end
    end

    def apple_pass_download_url
      return "#" unless self.pk_pass.attached?

      "#{ENV['SPREE_URL']}/api/v2/storefront/orders/download_apple_pass?card_type=Spree::GivexCard&card_id=#{self.id}"
    end

    def pdf_url
      return "" unless self&.store&.preferred_giftcard_pdf

      "#{ENV['SPREE_URL']}/api/v2/storefront/givex_cards/#{self.slug}/pdf_details"
    end

    def check_balance(store_id)
      balance_options = {card_number:self.givex_number,card_pin:""}
      store = Spree::Store.find_by('spree_stores.id = ?', store_id)
      result = Spree::GivexBalance.call(options: balance_options,store: store)
      return self.update(check_balance_reponse:result["value"]) if result["value"].is_a?(String)
      self.update(iso_code:result["value"][:iso_serial],check_balance_reponse:result["value"])
    end

    def post_generation_emails
      store = order.store
      product = line_item.product
      if product&.send_gift_card_via&.eql?('both') || product&.send_gift_card_via&.eql?('email')
        if store&.ses_emails
          SesEmailsDataWorker.perform_async(id, "digital_givex_card_recipient")
        else
          Spree::GeneralMailer.send_givex_cadentials_to_customer(self).deliver_now
        end
      end
      if (product&.send_gift_card_via&.eql?('sms') || product&.send_gift_card_via&.eql?('both')) && line_item.receipient_phone_number&.present?
        SmsWorker.perform_async(store.id, receipient_phone_number, 'Spree::GivexCard', slug)
      end
    end
  end
end
