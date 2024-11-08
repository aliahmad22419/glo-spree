class GenerateTsCardsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'ts_gift_cards', retry: 3

  def perform(shipment_id)
    shipment = Spree::Shipment.find(shipment_id)
    order = shipment.order
    gift_card_line_items = shipment.line_items.select { |line_item| GIFT_CARD_TYPES.include?(line_item.delivery_mode) }
    return if gift_card_line_items.empty?

    bulk_cards_hash = { ts_cards: [], givex_cards: [] }
    begin
      ActiveRecord::Base.transaction do
        gift_card_line_items.each do |line_item|
          bonus_card = line_item.eligible_bonus_card_promo

          if %w[tsgift_digital tsgift_physical].include?(line_item.delivery_mode)
            unless line_item.delivery_mode.eql?('tsgift_physical')
              line_item.quantity.times { bulk_cards_hash[:ts_cards].push({ line_item_id: line_item.id, order_id: order.id }) }
            end

            if bonus_card && line_item.product.ts_type.eql?('monetary')
              line_item.quantity.times { bulk_cards_hash[:ts_cards].push({ line_item_id: line_item.id, bonus: true, order_id: order.id }) }
            end
          elsif %w[givex_digital givex_physical].include?(line_item.delivery_mode)
            unless line_item.delivery_mode.eql?('givex_physical')
              line_item.quantity.times { bulk_cards_hash[:givex_cards].push({ line_item_id: line_item.id, order_id: order.id }) }
            end

            if bonus_card
              line_item.quantity.times { bulk_cards_hash[:givex_cards].push({ line_item_id: line_item.id, bonus: true, order_id: order.id }) }
            end
          end
        end

        create_cards(bulk_cards_hash)

        EnqueueGiftCardsGenerationWorker.perform_async(shipment_id)
        bulk_cards_hash[:ts_cards] = []
        bulk_cards_hash[:givex_cards] = []
      end
    rescue Exception => ex
      Rails.logger.error("issue generating cards: #{ex.message}")
      # notify_sns(ex.message, { title: 'issue generating cards', order_number: order.number, shipment_id: shipment_id})
      raise ex.message
    end
  end

  private

  def create_cards(bulk_cards_hash)
    if bulk_cards_hash[:ts_cards].present?
      Spree::TsGiftcard.create(bulk_cards_hash[:ts_cards])
    else
      Spree::GivexCard.create(bulk_cards_hash[:givex_cards])
    end
  end

  def notify_sns(message, options = {})
    Spree::SnsErrorLogger.call(options: {
      message_attributes: {
        data: {
          data_type: "String",
          string_value: (message += options.to_s).to_json
        }
      },
      message: message,
      logger_sns_topic_arn: options[:logger_sns_topic_arn]
    })
  end
end
