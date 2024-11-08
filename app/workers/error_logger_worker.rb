# ErrorLogger is responsible to observe orders with
# missing shipments, ts cards or givex cards
# and send notification to AWS SNS services
# where concerned people will know about the issue
# For details login techsembly's Jira account and check RDM-114
class ErrorLoggerWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'error_logging'

    def perform
        begin
            order_ids = []
            count = 0
            nonscheduled_orders = Spree::Order.complete.initiated.where(completed_at: 1.25.hours.ago..Time.zone.now).distinct

            scheduled_orders = Spree::Order.complete.initiated.joins([shipments: :shipping_methods])
                .where("spree_shipping_methods.scheduled_fulfilled = ?", true)
                .where(spree_shipments: { card_generation_datetime: 1.25.hours.ago..Time.zone.now }).distinct

            (nonscheduled_orders + scheduled_orders).uniq.each do |order|
                count = count+1 if order_ids.include?(order.id)
                order_ids.push(order.id)

                notify_shipments_if_issue(order)

                order.shipments.gift_card_shipments.each do |shipment|
                    next if shipment.scheduled?
                    notify_givex_ts_cards_if_issue(shipment.line_items.first)
                end
            end

            Rails.logger.info("Duplicate Order Count: #{count}")

        rescue Exception => e
            Rails.logger.error(e.message)
            return false
        end
    end

    def notify_shipments_if_issue(order)
        count_is, count_should_be = order.shipment_count_should_be

        unless count_should_be.eql?(count_is)
            message = "Order: #{order.number} has missing shipments (expected: #{count_should_be}, got: #{count_is})"

            # error_log = order.error_logs.find_or_initialize_by(error_type: 'shipment', status: 'failed')
            # unless error_log.persisted?
            #     order.update_column(:error_log_status, 'failed')
            #     error_log.message = message
            #     error_log.save
            # end

            if order.store.preferred_enabled_error_logging
                message_body = {
                    title: 'Missing shipments',
                    message: message,
                    meta: order_meta_data(order, 'Missing shipments')
                }
                notify_sns(message_body)
            end
        end
    end


    def notify_givex_ts_cards_if_issue(digital_line)
        order = digital_line.order
        bonus_card = digital_line.eligible_bonus_card_promo

        quantity_is, quantity_should_be = digital_line.givex_cards.is_generated.count, digital_line.quantity
        quantity_should_be = quantity_should_be * 2 if bonus_card
        if digital_line.delivery_mode.include?('givex_digital') && quantity_is < quantity_should_be
            message = "Order: #{digital_line.order.number} has missing GivexCards (expected: #{quantity_should_be}, got: #{quantity_is})"

            error_log = order.error_logs.find_or_initialize_by(error_type: 'givex_card', status: 'failed', message: message, line_item_id: digital_line.id)
            unless error_log.persisted?
                order.update_column(:error_log_status, 'failed')
                error_log.save
            end

            send_error_log_email(digital_line, message, 'Missing GivexCards')
        elsif digital_line.delivery_mode.include?('givex_digital') && quantity_is > quantity_should_be
            message = "Order: #{digital_line.order.number} has extra GivexCards (expected: #{quantity_should_be}, got: #{quantity_is})"

            error_log = order.error_logs.find_or_initialize_by(error_type: 'givex_card', status: 'exceeded', message: message, line_item_id: digital_line.id)
            unless error_log.persisted?
                order.update_column(:error_log_status, 'unresolved')
                error_log.save
            end

            send_error_log_email(digital_line, message, 'Extra GivexCards')
        elsif digital_line.delivery_mode.include?('givex_physical') && bonus_card
            # Assuming that when the delivery_mode is 'physical' and the bonus promo is eligible,
            # the quantity of the line_item will determine the number of bonus cards to be generated.

            quantity_is, quantity_should_be = digital_line.givex_cards.is_generated.count, digital_line.quantity
            if quantity_is < quantity_should_be
                message = "Order: #{order.number} has missing bonus GivexCards (expected: #{quantity_should_be}, got: #{quantity_is})"

                error_log = order.error_logs.find_or_initialize_by(error_type: 'givex_card', status: 'failed', message: message, line_item_id: digital_line.id)
                unless error_log.persisted?
                    order.update_column(:error_log_status, 'failed')
                    error_log.save
                end

                send_error_log_email(digital_line, message, 'Missing Bonus GivexCards')
            elsif quantity_is > quantity_should_be
                message = "Order: #{digital_line.order.number} has extra GivexCards (expected: #{quantity_should_be}, got: #{quantity_is})"

                error_log = order.error_logs.find_or_initialize_by(error_type: 'givex_card', status: 'exceeded', message: message, line_item_id: digital_line.id)
                unless error_log.persisted?
                    order.update_column(:error_log_status, 'unresolved')
                    error_log.save
                end
                send_error_log_email(digital_line, message, 'Extra Bonus GivexCards')
            end
        end
        
        quantity_is, quantity_should_be = digital_line.ts_giftcards.is_generated.count, digital_line.quantity
        quantity_should_be = quantity_should_be * 2 if bonus_card && digital_line.product.ts_type.eql?("monetary")
        if digital_line.delivery_mode.include?('tsgift_digital') && quantity_is < quantity_should_be
            message = "Order: #{digital_line.order.number} has missing TsCards (expected: #{quantity_should_be}, got: #{quantity_is})"

            error_log = order.error_logs.find_or_initialize_by(error_type: 'ts_card', status: 'failed', message: message, line_item_id: digital_line.id)
            unless error_log.persisted?
                order.update_column(:error_log_status, 'failed')
                error_log.save
            end

            send_error_log_email(digital_line, message, 'Missing TsCards')
        elsif digital_line.delivery_mode.include?('tsgift_digital') && quantity_is > quantity_should_be
            message = "Order: #{digital_line.order.number} has extra TsCards (expected: #{quantity_should_be}, got: #{quantity_is})"

            error_log = order.error_logs.find_or_initialize_by(error_type: 'ts_card', status: 'exceeded', message: message, line_item_id: digital_line.id)
            unless error_log.persisted?
                order.update_column(:error_log_status, 'unresolved')
                error_log.save
            end

            send_error_log_email(digital_line, message, 'Extra TsCards')
        elsif digital_line.product.ts_type.eql?("monetary") && bonus_card && digital_line.delivery_mode.include?('tsgift_physical')
            # Assuming that when the delivery_mode is 'physical' and the bonus promo is eligible,
            # the quantity of the line_item will determine the number of bonus cards to be generated.

            quantity_is, quantity_should_be = digital_line.ts_giftcards.is_generated.count, digital_line.quantity
            if quantity_is < quantity_should_be
                message = "Order: #{order.number} has missing bonus TsCards (expected: #{quantity_should_be}, got: #{quantity_is})"

                error_log = order.error_logs.find_or_initialize_by(error_type: 'ts_card', status: 'failed', message: message, line_item_id: digital_line.id)
                unless error_log.persisted?
                    order.update_column(:error_log_status, 'failed')
                    error_log.save
                end

                send_error_log_email(digital_line, message, 'Missing Bonus TsCards')
            elsif quantity_is > quantity_should_be
                message = "Order: #{digital_line.order.number} has extra bonus TsCards (expected: #{quantity_should_be}, got: #{quantity_is})"

                error_log = order.error_logs.find_or_initialize_by(error_type: 'ts_card', status: 'exceeded', message: message, line_item_id: digital_line.id)
                unless error_log.persisted?
                    order.update_column(:error_log_status, 'unresolved')
                    error_log.save
                end

                send_error_log_email(digital_line, message, 'Extra bonus TsCards')
            end
        end
    end

    def send_error_log_email(line_item, message, reason)
        if line_item.order.store.preferred_enabled_error_logging
            message_body = {
              title: reason,
              message: message,
              meta: order_meta_data(line_item.order, reason, line_item)
            }
            notify_sns(message_body)
        end
    end

    def order_meta_data(order, reason, line_item = nil)
      data = {
        customer_email: order.email,
        store_name: order.store.name,
        order_id: order.id,
        order_number: order.number,
        complete_order: order.serializable_hash,
        order_status: order.status,
        order_state: order.state,
        logs: "Customer Email: #{order.email}\nAccount Name: #{order.store.client.name || 'N/A'}\nStore Name: #{order.store.name}\nOrder ID: #{order.id}\nOrder #: #{order.number}\nOrder State: #{order.state}\nReason: #{reason}\n"
      }
      line_item ? data[:logs] += line_item.error_log_product_details : order.line_items.each { |item| data[:logs] += item.error_log_product_details }
      data
    end

    def notify_sns(body, options={})
        Spree::SnsErrorLogger.call(options: {
            message_attributes: {
                data: {
                    data_type: "String",
                    string_value: body.to_json
                }
            },
            message: body[:meta][:logs],
            logger_sns_topic_arn: options[:logger_sns_topic_arn]
        })
    end
end