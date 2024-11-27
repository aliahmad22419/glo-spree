namespace :givex_card_iso_serial do
  desc "Add the iso serial to givex card number"
  task :add_iso_serial => :environment do 
    givex_cards = Spree::GivexCard.where(iso_code:nil).where.not(store_id:nil)
    givex_cards.each do |givex_card| 
      if givex_card.store_id
          begin
            givex_card.check_balance(givex_card.store_id)
          rescue Exception => e
            puts e.message
            puts "##"*78
            puts givex_card.store_id
          end
      end
    end
  end
end