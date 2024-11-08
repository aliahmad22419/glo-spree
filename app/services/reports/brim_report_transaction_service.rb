
module Reports
  class BrimReportTransactionService
    def call
      @line_item_ids = []
      @time_range = 1.days.ago.beginning_of_day..1.days.ago.end_of_day
      # recent_orders = Spree::Order.complete.joins(:store).includes(:shipments, line_items: [:givex_cards, :ts_giftcards]).where("spree_orders.created_at >= ? AND spree_stores.test_mode = ?", 24.hours.ago.utc, false).order("completed_at DESC")     # this is only for production
      recent_orders = Spree::Order.complete.joins(:store).includes(:shipments, line_items: [:givex_cards, :ts_giftcards]).where(completed_at: @time_range, store: { test_mode: false }).order("completed_at DESC")
      recent_order_ids = recent_orders.map(&:id)
      recent_order_process(recent_orders) | legacy_order_process(recent_order_ids)
 
    end

    private

    def recent_order_process(recent_orders)

      records = []
      recent_orders.each do |order|
        order_detail_hash = order_details(order)
        records = records | order_line_items(order.line_items, order_detail_hash)
        records = records | order_shipments(order,order.price_values,order_detail_hash)
        records = records | order_adjustments(order,order_detail_hash)
        records = records | order_refunds(order.refunds, order_detail_hash)
      end

      return records
    end

    def legacy_order_process(recent_order_ids)
      ### Pervious Order refund now
      refunds = Spree::Refund.includes(:order).joins(order: :store).where(created_at: @time_range, store: { test_mode: false }).where.not(order: { id: recent_order_ids})
      records =  order_refunds(refunds)

      ### Pervious Order Schedule TsGiftCards
      ts_giftcards = Spree::TsGiftcard.joins(line_item: :store).where(created_at: @time_range, store: { test_mode: false }).where.not(line_item: { id: @line_item_ids.uniq.compact })
      ts_line_items = ts_giftcards.map{|t| t.line_item }
      records = records | order_line_items(ts_line_items.compact)

      ### Pervious Order Schedule GivexCards
      givex_cards = Spree::GivexCard.joins(line_item: :store).where(created_at: @time_range, store: { test_mode: false }).where.not(line_item: { id: @line_item_ids.uniq.compact })
      givex_line_items = givex_cards.map{|t| t.line_item }
      records = records | order_line_items(givex_line_items.compact)

      return records
    end

    def bonus_gift_cards(line_item)
      gift_cards = line_item.ts_giftcards.any? ? line_item.ts_giftcards : line_item.givex_cards
      gift_cards = gift_cards.where(bonus: true)
      return  gift_cards.any? ? gift_cards : nil
    end

    def id_generator(id, index, prefix = "")
      return prefix + id.to_s.rjust(15, '0') + (index).to_s.rjust(5, '0')
    end

    def activation_date(line_item)
      return unless ["tsgift_digital", "givex_digital"].include?(line_item.delivery_mode)

      gift_cards = line_item&.ts_giftcards.any? ? line_item&.ts_giftcards : line_item&.givex_cards
      activation_dates = []
      gift_cards.each do |gift_card|
        gift_card_number = gift_card.respond_to?(:givex_number) ? gift_card.givex_number : gift_card.number
        activation_dates.push(gift_card_number ? gift_card&.updated_at&.in_time_zone('Central Time (US & Canada)')&.strftime('%Y-%m-%d'): "")
      end
      return activation_dates
    end

    def round_off(number,decimal=2)
      number = number.to_s
      return (number.include?(".")? number.partition(".").last.length==1? number+"0" : number[..(number.index(".")+decimal)] : number + "." + "0"*decimal)
    end

    def shipment_discount_hash(hash_type:, order_number:, id:)
      {
        "Line item ID" => id,
        "Product ID" => order_number&.to_s + "-" + hash_type,
        "Product Title" => hash_type.capitalize,
        "Transaction Type" => hash_type.capitalize,
        "Product Type" => hash_type,
      }
    end

    def refund_hash(refund:, id:)
      {
        "Line item ID" => id,
        "Transaction Date" => refund&.created_at.in_time_zone('Central Time (US & Canada)')&.strftime('%Y-%m-%d'),
        "Transaction Type" => "Refund",
        "Refund Product Type" => refund&.payment_refund_type || "",
        "Refund Amount" => round_off(refund&.amount)

      }
    end

    def line_item_details(line_item, quantity)
      line_item_vendor = line_item&.vendor
      external_vendor_id, vendor_id = line_item_vendor&.external_vendor ? [line_item_vendor&.id, ''] : ['', line_item_vendor&.id]
      product_type = get_product_type(line_item)
      line_item.exchanged_prices = line_item.price_values

      {
        "Line item ID" =>  line_item.id.to_s.rjust(15, '0').ljust(20, '0'),
        "External Vendor ID" => external_vendor_id.present? ? external_vendor_id.to_s.rjust(6, '0') : "",
        "Vendor ID" => vendor_id.present? ? vendor_id.to_s.rjust(6, '0') : "",
        "Product ID" => line_item&.product_id.to_s.rjust(6, '0'),
        "Product Title" => line_item&.product&.name.slice(0, 32),
        "Transaction Date" => line_item&.order&.created_at&.in_time_zone('Central Time (US & Canada)')&.strftime('%Y-%m-%d'),
        "Transaction Type" =>  "Sale",
        "Order Subtotal" => round_off(line_item.price_values[:sub_total]),
        "Tax Exclusive" =>  value_per_quantity(line_item.total_tax_without_shipment(:additional), quantity),
        "Tax Inclusive" => value_per_quantity(line_item.total_tax_without_shipment(:included), quantity),
        "Product Type" => product_type,
        "Shipping Method" => line_item&.shipping_method_name,
        "Gift Card Type" => ["tsgift_digital", "givex_digital", "tsgift_physical", "givex_physical"].include?(line_item&.delivery_mode) ? line_item&.delivery_mode : "",
        "GC Serial Number" => line_item&.gift_card_serial_number_without_bouns&.first || "",
        "B2B - B2C" => line_item&.order&.bulk_order ? "Corporate" : "",
        "Activation Date" => activation_date(line_item)&.first || ""
      }
    end

    def order_details(order)
      order_payments = order&.payments&.completed
      {
        "Client ID" => order&.store&.client_id&.to_s&.rjust(6, '0'),
        "Storefront ID" => order&.store&.id&.to_s&.rjust(6, '0'),
        "Original Order Date" => order&.completed_at&.in_time_zone('Central Time (US & Canada)')&.strftime('%Y-%m-%d'),
        "Order Number" => order&.number,
        "Quantity" => 1,
        "Order Currency Code" => order&.currency,
        "Order Payment Method" => order_payments&.map{|payment| payment.payment_method.name }&.compact&.reject(&:blank?)&.join(','),
        "Card Type" => order.payment_method_type.in?(["Spree::Gateway::StripeGateway"]) ?
                       order_payments&.where&.not(source_type: "Spree::GiftCard")&.map{|payment| payment&.source&.cc_type || "" }&.compact&.uniq&.reject(&:blank?)&.join(',') : "",
        "Stripe Transaction ID" => order_payments&.map{|payment|  payment&.source && payment&.source["public_metadata"] ? payment&.source["public_metadata"]["pm_id"] || "" : "" }&.reject(&:blank?)&.join(','),
        "Card Country" => order_payments&.map{|payment|  payment&.source && payment&.source["public_metadata"] ?  payment&.source["public_metadata"]["country_code"] || "" : "" }&.reject(&:blank?)&.join(',')
      }
    end

    def bonus_card_details(gift_card)
      serial_number = gift_card.respond_to?(:iso_code) ? gift_card.iso_code : gift_card.serial_number
      {
        "Line item ID" =>  id_generator(gift_card.id, 0),   # 000000000000001000000  + (line_item.quantity + index)   if needed -> id_generator(line_item.quantity + index, 0) 
        "Transaction Type" => "Bonus", 
        "Gift Card Type" => gift_card.class.name == "Spree::TsGiftcard" ? "tsgift_digital" : "givex_digital",
        "GC Serial Number" => serial_number,
        "Activation Date" => serial_number ? gift_card&.updated_at&.in_time_zone('Central Time (US & Canada)')&.strftime('%Y-%m-%d') : "",
        "Order Subtotal" => round_off(gift_card.balance),  # gift_card balance
        "Tax Exclusive" => "0.00",
        "Tax Inclusive" => "0.00"
      }
    end


    def order_refunds(refunds, order_detail_hash=nil)
      records = []
      updated_order_details = order_detail_hash ? false : true
      refunds&.each_with_index do |refund,index| # refund.id = 1
        # line_item_id = RF000000000000001
        order_detail_hash = order_details(refund.order) if updated_order_details
        order_detail_hash["Quantity"] = ""
        refund_hash = refund_hash(refund: refund, id: "RF" + refund.id.to_s.rjust(14, '0'))
        records << order_detail_hash.merge(refund_hash)
      end
      return records
    end

    def order_line_items(line_items, order_detail_hash=nil)
      records = []
      updated_order_details = order_detail_hash ? false : true
      line_items.each do |line_item|
        order_detail_hash = order_details(line_item.order) if updated_order_details
        @line_item_ids.push(line_item.id)
        line_item_quantity = line_item.quantity
        line_item_records =  line_item_details(line_item, line_item_quantity)
        records << order_detail_hash.merge(line_item_records)

        if line_item_quantity > 1
          gift_card_serial_number_without_bouns = line_item&.gift_card_serial_number_without_bouns
          (line_item_quantity-1).times do |index|  # line_item.id = 1
            hash = records.last.dup
            hash["Line item ID"] =  id_generator(line_item.id, index+1)   # 000000000000001000000 + index
            hash["GC Serial Number"] = gift_card_serial_number_without_bouns ? (gift_card_serial_number_without_bouns[index+1] || "" ): ""
            hash["Activation Date"] = activation_date(line_item) ? (activation_date(line_item)[index+1] || "") : ""
            records << hash
          end
        end

        gift_cards = bonus_gift_cards(line_item)
        if gift_cards
          gift_cards.each_with_index do |gift_card, index|   # gift_card.id = 1
            hash = records.last.dup
            records << hash.merge(bonus_card_details(gift_card))
          end
        end
      end
      return records
    end

    def order_shipments(order, price_values, order_detail_hash)
      # order sepecfic shipments
      records = []
      shipments = price_values[:shipments]
      shipment_costs = price_values[:prices][:shipment_prices][:cost]
      shipments.each do |shipment| # shipment.id = 1
        # line_item_id = SH000000000000001000000
        shipment_hash = shipment_discount_hash(hash_type: "shipping", order_number: order.number, id: id_generator(shipment.id, 0,"SH"))
        shipment_hash["Shipping Amount"] = round_off(shipment_costs[shipment.id]["shipment_cost"])
        shipment_hash["Tax Exclusive"] = round_off(shipment_costs[shipment.id]["additional_tax"])
        shipment_hash["Tax Inclusive"] = round_off(shipment_costs[shipment.id]["included_tax"])
        records << order_detail_hash.merge(shipment_hash)
      end
      return records
    end

    def order_adjustments(order, order_detail_hash)
      records = []
      # order sepecfic adjustments/disconts
      adjustments = Spree::Adjustment.where(order_id: order.id, source_type: "Spree::PromotionAction")  
      if adjustments.any?
        discount_hash = shipment_discount_hash(hash_type: "discount", order_number: order.number, id: id_generator(adjustments.first.id, 0,"DS"))
        discount_hash["Discount Amount"] = round_off(order.price_values[:prices][:promo_total])
        records << order_detail_hash.merge(discount_hash)
      end
      return records
    end

    def get_product_type(line_item)
      product = line_item&.product
      return  product&.product_type == "simple" ? "product" : product&.product_type == "gift" && product&.ts_type.present? ? product&.ts_type : product.product_type 
    end

    def value_per_quantity(value, quantity)
      round_off(value && quantity && value > 0 && quantity > 0 ? value / quantity : value)
    end
  end
end
