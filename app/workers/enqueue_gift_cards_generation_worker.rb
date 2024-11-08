class EnqueueGiftCardsGenerationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ts_givex_cards_generator, retry: 3

  def perform(shipment_id)
    shipment = Spree::Shipment.find(shipment_id)

    shipment.line_items.each do |line_item|
      line_item.ts_giftcards.not_generated.processable.each { |gift_card| GiftCardsGenerateWorker.perform_async(gift_card.id, gift_card.class.to_s) }
      line_item.givex_cards.not_generated.processable.each { |gift_card| GiftCardsGenerateWorker.perform_async(gift_card.id, gift_card.class.to_s) }
    end
  end
end
