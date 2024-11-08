# Make sure every card class has column/method named 'card_generated'
# which shows if card is generated successfully by supported api like TS, GIVEX
# and also enum defined as { processable: 0, processing: 1, processed: 2 }
# which shows if card is already processing or not
# both combined ensure card generation only if not already generated or requested
class GiftCardsGenerateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ts_givex_cards_generator, retry: false

  def perform(id, klass)
    card = klass.constantize.find_by('id = ?', id)
    # if !card.card_generated && card.processable?
    #   card.processing!
    #   card.generate_card
    # end
    card.generate_card if !card.card_generated && card.processable?
  end
end