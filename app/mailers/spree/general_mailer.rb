module Spree
  class GeneralMailer < BaseMailer

    def set_prices
      attrs = @order.price_values(nil, @vendor.try(:id))
      @line_items = attrs[:line_items]
      @shipments = attrs[:shipments]
    end

    def send_email_to_customer answer
      question = answer.question
      @name = question.guest_name
      @answer = answer.title
      @question = question.title
      @store = question.store

      if question.vendor.microsite
        @vendor_page = question.questionable_id.present? ? "https://"+question.store.url+"/vendor/"+question.vendor.landing_page_url.to_s+"?question_id="+question.id.to_s+"&order_id="+question.questionable_id.to_s : "https://"+question.store.url+"/vendor/"+question.vendor.landing_page_url.to_s+"?question_id="+question.id.to_s
      end

      mail(to: question.guest_email, cc: cc_store_recipients(@store), subject: "Answer to your query")
    end

    def send_order_email_to_customer to, from, message, logo_url, store, question=nil
      @message = message
      @to = to
      @store = store
      @client_logo = logo_url
      @vendor_page = "https://"+question.store.url+"/vendor/"+question.vendor.landing_page_url.to_s+"?question_id="+question.id.to_s+"&order_id="+question.questionable_id.to_s if question.vendor.microsite == true
      mail(to: to, from: from, cc: cc_store_recipients(@store).uniq, subject: "You have a new message")
    end

    def send_question_email_to_vendor question
      vendor_email = question.vendor.users.first.email
      @customer_name = question.guest_name
      @question = question.title
      @vendor = question.vendor
      @vendor_name = @vendor.name
      @store = question.store
      mail(to: vendor_email, cc: cc_store_recipients(@store), subject: "#{@customer_name} sent you a message")
    end

    def send_otp user
      @user = user
      if user.has_spree_role?('client')
        @client = user
      elsif user.has_spree_role?('vendor')
        @client =  user&.vendors&.last&.client&.users.joins(:spree_roles).where(spree_roles: {name: 'client'}).last
      else
        @client = user.client.users.joins(:spree_roles).where(spree_roles: {name: 'client'}).last
      end
      mail(to: user.email, subject: I18n.t('general_mailer.one_time_password.subject'), from: @client.email )
    end

    def send_request_question_to_follower question
      request = question&.questionable
      to = request&.followee&.email
      from = request&.follower&.email
      @name = request&.name
      @message = question.title
      mail(to: to, from: from, subject: "#{from} sent you a message")
    end

    def send_gift_card_cadentials_to_customer gift_card
      @gift_card = gift_card
      @gift_card_code = gift_card.code
      @order = @gift_card&.line_item&.order
      set_prices
      @shipping_address = @order&.shipping_address
      @store = @order.try(:store)
      @contact_us = "mailto:" + @store&.mail_from_address
      from = @order&.email || @order&.user&.email
      mail(to: gift_card.email, from: from, subject: "You've received a gift card")
    end

    def send_follow_request_to_vendor name, from, to, details
      @customer_name = name
      @details = details
      mail(to: to, from: from, subject: "#{@customer_name} sent you a follow request")
    end

    def send_follow_request_status_to_customer name, to, from, status
      @customer_name = name
      @status = status
      mail(to: to, from: from, subject: "Your follow request is #{status}")
    end

    def send_givex_cadentials_to_customer givex_card
      @order = givex_card&.order
      @store = @order.try(:store)
      @email = givex_card&.customer_email
      @recipient_name = "#{givex_card&.customer_first_name} #{givex_card&.customer_last_name}"
      @givx_number = givex_card&.givex_number
      @givex_pin = givex_card&.givex_transaction_reference&.split(':')[1]
      @sender_email = givex_card&.user&.email
      @sender_name = "#{givex_card&.order&.bill_address&.full_username}"
      @line_item = givex_card&.line_item
      @gift_message = @line_item&.message
      @balance = givex_card&.balance
      @product_title = @line_item&.product.name
      @image_url = @line_item.voucher_image_url

      @passbook = givex_card&.pk_pass
      attachments[@passbook.filename.to_s] = open(@passbook.service_url) {|f| f.read } if @passbook&.attached?

      mail(to: @email, subject: 'Gift Card Received')
    end

    def send_confirmation_to_purchaser givex_card
      @gift = givex_card
      @recipient_name = "#{@gift&.customer_first_name} #{@gift&.customer_last_name}"
      @order = @gift&.order
      @store = @order.try(:store)
      @line_item = @gift&.line_item
      mail(to: @order&.email, subject: 'Gift Card Confirmation')
    end

    def send_ts_cadentials_to_customer ts_card
      @order = ts_card&.order
      @store = @order.try(:store)
      @email = ts_card&.customer_email
      @recipient_name = "#{ts_card&.customer_first_name} #{ts_card&.customer_last_name}"
      @givx_number = ts_card&.number
      @givex_pin = ts_card&.pin
      @sender_email = ts_card&.user&.email
      @sender_name = "#{ts_card&.order&.bill_address&.full_username}"
      @line_item = ts_card&.line_item
      @image_url = @line_item.voucher_image_url
      @gift_message = @line_item&.message
      @balance = ts_card&.balance
      @product_title = @line_item&.product.name

      @passbook = ts_card&.pk_pass
      attachments[@passbook.filename.to_s] = open(@passbook.service_url) {|f| f.read } if @passbook&.attached?

      mail(to: @email, subject: 'Gift Card Received')
    end
  end
end