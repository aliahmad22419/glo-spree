module Spree
  class TsGiftcard < Spree::Base
    has_one_attached :pk_pass
    has_many :log_entries, as: :source
    has_many :bookkeeping_documents, as: :printable, dependent: :destroy
    has_many :history_logs, :as => :loggable
    include GiftCardConcern
    belongs_to :user, :class_name => 'Spree::User'
    belongs_to :order, :class_name => 'Spree::Order'
    belongs_to :line_item, :class_name => 'Spree::LineItem'
    belongs_to :store, class_name: 'Spree::Store'
    before_create :set_slug
    after_create :set_reference_number
    enum send_gift_card_via: { sms: 0, email: 1, both: 2 }
    enum status: { initiated: 0, active: 1, blocked: 2, canceled: 3, lost: 4 }
    enum request_state: { processable: 0, processing: 1, processed: 2 }

    scope :without_store, -> { where("store_id IS NULL")}
    scope :is_generated, -> { where(card_generated: true) }
    scope :not_generated, -> { where(card_generated: false) }
    scope :bonus_cards, -> { where(bonus: true) }

    def generate_card
      processing!

      store = order.store
      product = line_item.product
      shipping_address_data = {}
      first_name = line_item.receipient_first_name
      last_name = line_item.receipient_last_name
      phone_number = line_item.receipient_phone_number
      send_gift_card_via = product.send_gift_card_via
      delivery_mode = line_item.delivery_mode.eql?('tsgift_digital') ? "digital" : "physical"
      email = line_item.receipient_email

      if line_item.delivery_mode.eql?('tsgift_physical')
        shipping_address = order.shipping_address
        shipping_address_data = { firstname: shipping_address.firstname, lastname: shipping_address.lastname,
                                  address1: shipping_address.address1, address2: shipping_address.address2,
                                  city: shipping_address.city, zipcode: shipping_address.zipcode,
                                  phone: shipping_address.phone, state_name: shipping_address&.state_name,
                                  state: shipping_address&.state&.name, country: shipping_address&.country&.name }
        send_gift_card_via = ""
      end

      prices = line_item.price_values(order.currency)
      amount = prices[:sub_total].to_f
      if bonus
        amount = (amount * store.preferred_bonus_percentage.to_i) / 100
        billing_address = order&.billing_address
        first_name = billing_address&.firstname
        last_name = billing_address&.lastname
        phone_number = line_item.receipient_phone_number.present? ? billing_address&.phone : nil
        email = order.email
        send_gift_card_via = product.send_gift_card_via
        delivery_mode = "digital"
      end

      options = { amount: amount, store_id: store.id, currency: order.currency,
                  card_type: product.ts_type, skus: [line_item.sku],
                  campaign_code: product.campaign_code.strip, product_name: line_item.name,
                  delivery_mode: delivery_mode, recipient_first_name: first_name, recipient_last_name: last_name,
                  receipient_email: email, receipient_phone_number: phone_number, order_number: order.number,
                  shipping_address: shipping_address_data, customer_email: order&.user&.email,
                  bonus: bonus, spree_ts_giftcard_id: id, user_id: order.user_id,
                  order_placed_date: order.completed_at, request_id: reference_number,
                  meta: {
                    "spree_client": {
                      variant_option_values: line_item&.option_values_text,
                      customization_values: line_item.generate_customization_values
                    }
                  }
                }

      result = Spree::GenerateTsgiftCard.call(options: options)
      update_column(:response, result.to_json)

      if result && result.value['id'].to_i.nonzero?
        update_columns(card_generated: true, request_state: :processed)

        result_value = result.value
        update({
                 customer_email: email, customer_first_name: first_name, customer_last_name: last_name,
                 receipient_phone_number: phone_number, user_id: order.user_id, line_item_id: line_item.id,
                 order_id: order.id, store_id: store.id, send_gift_card_via: send_gift_card_via,
                 number: result_value['number'], barcode_key: result_value['barcode_key'],
                 qrcode_key: result_value['qrcode_key'], pin: result_value['pin'], balance: result_value['value'],
                 status: 'active', expiry_date: result_value['value']['expiry_date'],
                 serial_number: result_value['serial_number'] })

        ApplePass.new(self).send(:attach)
        post_generation_emails
      else
        processable!
        log_entries.create(details: result.to_json)
      end
    rescue => exception
      processable!
      log_entries.create(details: exception.message)
    end

    def generate_ts_gift_card
      {balance: balance? ? self&.line_item&.display_exchanged(balance) : "", balance_amount: balance? ? ("%.2f" % balance)&.to_s : "", as_at: order&.created_at&.strftime('%d/%m/%y'), expiray_date: JSON.parse(response)["value"]["expiry_date"]&.to_date&.strftime('%d/%m/%y'),
        number: number,serial_number: serial_number, pin: pin, message: line_item&.message&.to_s, receipient_first_name: customer_first_name&.to_s, receipient_last_name: customer_last_name&.to_s,
        from_name_first_name: order&.bill_address&.firstname, from_name_last_name:  order&.bill_address&.lastname, product_name: line_item.product&.name, store_url: "https://#{store&.url}", product_slug: line_item&.variant&.product&.slug,
        image_url: line_item&.voucher_image_url, store_name: store&.name, sender_name: (bonus? ? "#{order&.bill_address&.full_username}" : line_item&.sender_name), receipient_email: line_item&.receipient_email, store_url: "https://#{order&.store.url}",
        barcode_url: get_s3_object_url(barcode_key), qrcode_url: get_s3_object_url(qrcode_key), recipient_email_link: line_item&.product&.recipient_email_link, vendor_name: line_item&.product&.vendor&.name, sms_link: "https://#{order&.store.url}/tsgift/#{slug}",
        bonus: bonus, pk_pass_attached: self.pk_pass.attached?, pk_pass_url: self.apple_pass_download_url , brand_name: line_item&.product&.brand_name, terms_and_conditions: line_item&.product&.preferred_terms_and_conditions, pdf_url: self.pdf_url,
        order: self&.order&.attributes, order_number: self&.order&.number, line_items: (self.line_item&.ses_email_data || []), currency: order&.currency, currency_symbol: Spree::Money.new(order&.currency)&.currency&.symbol, language: (store&.preferred_default_language || 'en')
      }
    end

    def generate_ts_gift_card_external
      {
        receipient_first_name: customer_first_name&.to_s, receipient_last_name: customer_last_name&.to_s, number: number&.to_s,
        pin: pin&.to_s, as_at: Date.parse(JSON.parse(response)["created_at"])&.strftime('%d %b %Y'), expiray_date: Date.parse(JSON.parse(response)["expiry_date"])&.strftime('%d %b %Y')&.to_s,
        balance: JSON.parse(response)["value"]&.to_s, image_url: image_url, sms_link: "#{ENV['GIFTCARD_SMS_HOST']}/tsgift_ex/#{slug}", barcode_url: get_s3_object_url(barcode_key), qrcode_url: get_s3_object_url(qrcode_key)
      }
    end

    def self.generete_and_send_sms(result, current_client)
      card = Spree::TsGiftcard.create!(number: result["number"],serial_number: result["serial_number"], pin: result["pin"], balance: result["balance"],
                               card_generated: true, customer_email: result["recipient_email"], customer_first_name: result["recipient_first_name"],
                               customer_last_name: result["recipient_last_name"], response: result.to_json,
                               campaign_id: result["campaign_id"],campaign_body: result["campaign_body"], image_url: result["image_url"],
                               receipient_phone_number: result["receipient_phone_number"], send_gift_card_via: result["send_gift_card_via"])
      card.send_sms(current_client) if card.send_gift_card_via == "sms" || card.send_gift_card_via == "both"
    end

    def post_generation_emails
      product = line_item.product
      if product.delivery_mode != "tsgift_physical" || bonus
        if product.send_gift_card_via.eql?("both") || product.send_gift_card_via.eql?("email")
          if self.customer_email.present?
            if self.order.store.ses_emails
              SesEmailsDataWorker.perform_async(self.id, "digital_ts_card_recipient")
            else
              Spree::GeneralMailer.send_ts_cadentials_to_customer(self).deliver_now
            end
          end
        end
        if (product.send_gift_card_via.eql?("sms") || product.send_gift_card_via.eql?("both")) && line_item.receipient_phone_number.present?
          SmsWorker.perform_async(order.store.id, self.receipient_phone_number, "Spree::TsGiftcard", self.slug)
        end
      end
    end

     def send_sms current_client
       begin
         body = campaign_body
         param_values = generate_ts_gift_card_external
         param_values&.stringify_keys!
         body = body.gsub(/\{\{(.*?)\}\}/) { |match| "#{param_values[$1.strip.tr "{{}}", '']} " }
         SmsWorker.send_sms(body, current_client&.from_phone_number, receipient_phone_number)
       rescue => e
         Rails.logger.error(e.message)
       end
     end

    def set_slug
      loop do
        self.slug = SecureRandom.uuid
        break unless Spree::TsGiftcard.where(slug: slug).exists?
      end
    end

    def set_reference_number
      reference_number = "TS#{id}#{SecureRandom.random_number(10 ** 4).to_s.rjust(4, '0')}"
      update_column(:reference_number, reference_number)
    end

    def apple_pass_download_url
      return "#" unless self.pk_pass.attached?

      "#{ENV['SPREE_URL']}/api/v2/storefront/orders/download_apple_pass?card_type=Spree::TsGiftcard&card_id=#{self.id}"
    end

    def pdf_url
      return "" unless self.store.preferred_giftcard_pdf

      "#{ENV['SPREE_URL']}/api/v2/storefront/ts_gift_cards/#{self.slug}/pdf_details"
    end

  end
end
