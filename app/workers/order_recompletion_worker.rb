# OrderRecompletionWorker is responsible to observe orders with
# missing shipments, ts cards or givex cards
# and re-attempt to create again 4 times

class OrderRecompletionWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'recompletion'

  def perform
    Spree::Order.complete.failed.find_each do |order|
      process_order(order)
    end
  rescue => e
    Rails.logger.error(e.message)
  end

  private

  def process_order(order)
    failed_logs = order.error_logs.failed.where('attempts < ?', 3)

    # retry_shipment(failed_logs.shipment.first) if failed_logs.shipment.present?

    failed_logs.each do |log|
      regenerate_gift_cards(log) unless log.shipment?
    end

    unless order.reload.error_logs.failed.exists?
      if order.error_logs.unresolved.exists?
        order.update_column(:error_log_status, 'unresolved')
      else
        order.update_column(:error_log_status, 'resolved')
      end
    end
  end

  def retry_shipment(shipment_log)
    shipment_log.order.create_proposed_shipments
    count_is, count_should_be = shipment_log.order.shipment_count_should_be

    if count_should_be == count_is
      reloaded_order = shipment_log.order.reload
      reloaded_order.shipments.find_each do |shipment|
        shipment.shipping_rates.first.update(selected: true)
      end

      reloaded_order.update_with_updater!

      reloaded_order.shipments.where(delivery_mode: DIGITAL_TYPES).each do |shipment|
        shipment.line_items.each {|line_item| retry_cards_if_any(line_item) }
      end

      shipment_log.successful!
    end
    shipment_log.update(attempts: shipment_log.attempts + 1)
  end

  def retry_cards_if_any(digital_line)
    order = digital_line.order.reload
    bonus_card = digital_line.eligible_bonus_card_promo

    quantity_is, quantity_should_be = digital_line.givex_cards.is_generated.count, digital_line.quantity
    quantity_should_be = quantity_should_be * 2 if bonus_card
    if digital_line.delivery_mode.include?('givex_digital') && quantity_is < quantity_should_be
      message = "Order: #{digital_line.order.number} has missing GivexCards (expected: #{quantity_should_be}, got: #{quantity_is})"

      error_log = order.error_logs.find_or_initialize_by(error_type: 'givex_card', status: 'failed')
      unless error_log.persisted?
        order.update_column(:error_log_status, 'failed')
        error_log.message = message
        error_log.save
        regenerate_gift_cards(error_log.reload)
      end
    end

    quantity_is, quantity_should_be = digital_line.ts_giftcards.is_generated.count, digital_line.quantity
    quantity_should_be = quantity_should_be * 2 if bonus_card && digital_line.product.ts_type.eql?("monetary")
    if digital_line.delivery_mode.include?('tsgift_digital') && quantity_is < quantity_should_be
      message = "Order: #{digital_line.order.number} has missing TsCards (expected: #{quantity_should_be}, got: #{quantity_is})"

      error_log = order.error_logs.find_or_initialize_by(error_type: 'ts_card', status: 'failed')
      unless error_log.persisted?
        order.update_column(:error_log_status, 'failed')
        error_log.message = message
        error_log.save
        regenerate_gift_cards(error_log.reload)
      end
    end
  end

  def regenerate_gift_cards(log)
    if log.ts_card?
      return log_invalid_store_settings('TS', log.order.store) if log.order.store.giftcard_config_blank?

      generate_cards(log) if log.line_item.ts_giftcards.not_generated.any?

      if log.line_item.delivery_mode.include?('tsgift_digital')
        log.successful! if (log.line_item.quantity * (log.line_item.eligible_bonus_card_promo ? 2 : 1)) == log.line_item.reload.ts_giftcards.is_generated.count
      elsif log.line_item.delivery_mode.include?('tsgift_physical') && log.line_item.eligible_bonus_card_promo
        log.successful! if log.line_item.reload.ts_giftcards.is_generated.bonus_cards.count == log.line_item.quantity
      end
    elsif log.givex_card?
      return log_invalid_store_settings('GiveX', log.order.store) if log.order.store.giftcard_config_blank?('givex')

      generate_cards(log) if log.line_item.givex_cards.not_generated.any?

      if log.line_item.delivery_mode.include?('givex_digital')
        log.successful! if (log.line_item.quantity * (log.line_item.eligible_bonus_card_promo ? 2 : 1)) == log.line_item.reload.givex_cards.is_generated.count
      elsif log.line_item.delivery_mode.include?('givex_physical') && log.line_item.eligible_bonus_card_promo
        log.successful! if log.line_item.reload.givex_cards.is_generated.bonus_cards.count == log.line_item.quantity
      end
    end
    log.update(attempts: log.attempts + 1)
  end

  def generate_cards(log)
    case log.error_type
    when 'ts_card'
      log.line_item.ts_giftcards.not_generated.processable.find_each { |card| card.generate_card }
    when 'givex_card'
      log.line_item.givex_cards.not_generated.processable.find_each { |card| card.generate_card }
    end
  end

  def log_invalid_store_settings(card_type, store)
    Rails.logger.info("Missing configurations for #{card_type} in store #{store.name} settings")
  end
end

