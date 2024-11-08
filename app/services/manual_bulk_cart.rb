# options = { email: 'zeeshan@techsembly.com', store_id: 533, currency: 'USD' }
# STEP 1: Create order and add items
# BulkCart.new('bulk_order_test.csv', options).create_cart_and_add_items
class ManualBulkCart
    attr_accessor :file_path, :options, :currency, :store, :email

    def initialize(file_name='public/cart-items.csv', options={})
        @file_path = "#{Rails.root}/public/#{file_name}"
        @currency = options[:currency]
        @store = Spree::Store.find(options[:store_id])
        @email = options[:email]

        raise 'Please provide email, store id and currency' if @email.blank? || @store.blank? || @currency.blank?

        get_current_user_and_delete_incomplete_carts
    end

    def create_cart_and_add_items
      order_params = { user: @user, store: @store, currency: @currency }

      spree_current_order = Spree::Api::Dependencies.storefront_cart_create_service.constantize.call(order_params).value

      CSV.foreach(@file_path, :headers => true) do |row|
        # Product's sku / master variant's sku
        @variant = Spree::Product.find_by_id(row[1].strip)&.master
        raise "No product with provided sku found: #{row[1]}" if @variant.blank?
        raise "Forbidden Entity" if Spree::XssValidationConcern.forbidden_tag_exist? row.to_s
        next if spree_current_order.line_items.find_by_variant_id(@variant.id).present?

        params = { options: { store_id: @store.id }, quantity: (row[8]&.strip || 1) }

        result = Spree::Api::Dependencies.storefront_cart_add_item_service.constantize.call(
          order: spree_current_order,
          variant: @variant,
          quantity: params[:quantity],
          options: params[:options]
        )

        line_item = result.value
        raise "#{line_item.errors.full_messages}" if line_item.errors.present?

        if result.success
          line_item.receipient_first_name = row[2].strip
          line_item.receipient_last_name = row[3].strip
          line_item.receipient_email = row[4].strip
          line_item.message = row[5]&.strip
          line_item.sender_name= row[6].strip

          if row[7]&.strip.present?
            line_item.custom_price = row[7].strip
            line_item.price = 0
            line_item.add_delivery_charges_to_price
            line_item.pre_tax_amount = [line_item.price, line_item.custom_price].max
          end
          line_item.save
        end
      end
      Rails.logger.info("Order Number: #{spree_current_order.number}")
    end

    def get_current_user_and_delete_incomplete_carts
        @user = Spree::User.where(email: @email, store_id: @store.id).first
        if @user.blank?
          @user = Spree.user_class.new(email: @email, password: @email, store_id: @store.id)
          role = Spree::Role.find_by_name "customer"
          @user.spree_roles << role
          @user.save
        end

        @user.orders.incomplete.where(store_id: @store.id).destroy_all
    end

    # STEP 2: Create Voucher
    def create_voucher(attrs = { number: 'R005812581', sku: '000968' })
      variant_id = Spree::Product.find(attrs[:sku]).master.id
      order = Spree::Order.find_by(number: attrs[:number])
      raise "No order found" if order.blank?

      amount = order.price_values[:prices][:payable_amount]

      attrs[:variant_id] = variant_id
      attrs[:client_id] = order.store.client_id
      attrs[:email] = order.email
      attrs[:name] = order.store.name
      attrs[:currency] = order.currency
      attrs[:current_value] = amount
      attrs[:original_value] = amount
      attrs[:enabled] = true

      attrs.delete(:number)
      attrs.delete(:sku)
      gift_card = Spree::GiftCard.create(attrs)

      Rails.logger.info("Voucher Card Number: #{gift_card.code}")
    end

    # STEP 3: Complete bulk order
    def apply_voucher_and_complete_order(options = { number: 'R005812581', code: 'InrWVGOcx705' })
      order = Spree::Order.find_by(number: options[:number])
      gift_card = Spree::GiftCard.find_by_code(options[:code])

      order.update_attribute(:state, "payment")
      order.add_gift_card_payments(gift_card)
      order.update_attribute(:state, "confirm")
      order.next!
    end
end
