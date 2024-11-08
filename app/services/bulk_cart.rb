# options =
# STEP 1: Create order and add items
# BulkCart.new('bulk_order_test.csv', options).create_cart_and_add_items
class BulkCart
  def create_bulk_order(options)
    set_data(options)

    ActiveRecord::Base.transaction do
      spree_current_order = Spree::Api::Dependencies.storefront_cart_create_service.constantize.call({ user: nil, order_params: {email: @email}, store: @store, currency: @currency } ).value
      @data.each do |row|
        raise "Forbidden Entity" if Spree::XssValidationConcern.forbidden_tag_exist? row.to_s
        indexed_names = {
          "sku": row[0],
          "variant_sku": row[1],
          "recipient_first_name": row[2],
          "recipient_last_name": row[3],
          "recipient_email": row[4],
          "gift_message": row[5],
          "sender_name": row[6],
          "gift_card_value": row[7],
          "quantity": row[8]
        }

        @product = @store.products.find_by(client_id: @current_user.client_id, id: indexed_names[:sku]&.strip)
        raise "No product with provided sku: #{indexed_names[:sku]} found" if @product.blank?

        find_variant(indexed_names[:variant_sku]&.strip)
        raise "Product with sku: #{indexed_names[:sku]} has no variant: #{indexed_names[:variant_sku]&.strip}" unless @variant.present?

        unless @product.product_type.eql?('gift') && ['givex_digital', 'tsgift_digital'].include?(@product.delivery_mode)
          raise "Only Gift Card digital is allowed for bulk order"
        end

        params = { options: { store_id: @store.id, glo_api: true }, quantity: (indexed_names[:quantity]&.strip || 1) }

        result = Spree::Api::Dependencies.storefront_cart_add_item_service.constantize.call(
                  order: spree_current_order,
                  variant: @variant,
                  quantity: params[:quantity],
                  options: params[:options]
                )

        line_item = result.value
        raise "#{line_item.errors.full_messages}" if line_item.errors.present?

        blank_fields = ""
        blank_fields << "Receipient first name" unless indexed_names[:recipient_first_name].present?
        blank_fields << "#{', ' if blank_fields.present?}Receipient last name" unless indexed_names[:recipient_last_name].present?
        blank_fields << "#{', ' if blank_fields.present?}Receipient email" unless indexed_names[:recipient_email].present?
        blank_fields << "#{', ' if blank_fields.present?}Sender name" unless indexed_names[:sender_name].present?
        raise "#{blank_fields} not given for #{indexed_names[:sku]}" if blank_fields.present?

        if result.success
          line_item.receipient_first_name = indexed_names[:recipient_first_name]&.strip
          line_item.receipient_last_name = indexed_names[:recipient_last_name]&.strip
          line_item.receipient_email = indexed_names[:recipient_email]&.strip
          line_item.message = indexed_names[:gift_message]&.strip
          line_item.sender_name= indexed_names[:sender_name]&.strip

          if indexed_names[:gift_card_value]&.strip.present?
            line_item.custom_price = indexed_names[:gift_card_value]&.strip
            line_item.price = 0
            line_item.add_delivery_charges_to_price
            line_item.pre_tax_amount = [line_item.price, line_item.custom_price].max
          end
          line_item.save
        end
      end
      return spree_current_order
    end
  end

  def attach_address(params, order)
    if order.shipping_address.present?
      order.shipping_address.update(address_params(params, order&.bulk_order&.user))
      order.billing_address.update(address_params(params, order&.bulk_order&.user))
    else
      order.create_ship_address(address_params(params, order&.bulk_order&.user))
      order.create_bill_address(address_params(params, order&.bulk_order&.user))
    end

    select_shipping_rates(order)
    order.next! if order.state == "address"
    order.next! if order.reload.state == "delivery"
  end

  private

  def address_params(param, current_user)
    @country = set_country_by_iso(param[:address][:country]) if (param[:address][:country])
    param[:address].merge!({country_id: @country.id, user_id: current_user.id}).delete(:country)
    return param[:address].permit(:address,:firstname,:lastname,:address1,:address2,:city,:state_id,:zipcode,:country_id,:phone,:state_name,:region,:district,:estate_name,:apartment_no,:country_id,:user_id)
  end

  def get_csv_data(csv_file)
    return CSV.parse(csv_file.read, headers: true)
  end

  def select_shipping_rates(order)
    calculated_shipments = order.create_proposed_shipments
    raise "We are unable to calculate shipping rates, please check shipping category/method" unless calculated_shipments

    calculated_shipments.each { |shipment| shipment.shipping_rates[0]&.update_column(:selected, true) }
  end

  def set_country_by_iso(country_iso)
    return Spree::Country.find_by(iso: country_iso)
  end

  def set_data(options)
    raise "Error in reading file, client/sub-client must exist" unless options[:user]&.client.present?

    @data  = get_csv_data(options[:csv_file])
    raise "Invalid csv file, please check and upload again" if @data.length == 0

    @current_user = options[:user]
    @currency = options[:currency].presence
    @email = options[:email].presence
    @store = @current_user.client.stores.find_by('spree_stores.id = ?', options[:store_id])

    blank_fields = ""
    blank_fields << "Purchaser email" unless @email
    blank_fields << "#{', ' if blank_fields.present?}Currency" unless @currency
    blank_fields << "#{', ' if blank_fields.present?}Store" unless @store
    raise "#{blank_fields} required" if blank_fields.present?
  end

  def find_variant variant_sku
    return @variant = @product.master unless variant_sku

    @variant = @product.variants.find_by(sku: variant_sku)
    raise "Unable to find variant of sku: #{@product.sku}" unless @variant
  end
end
