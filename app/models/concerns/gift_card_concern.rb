module GiftCardConcern
	extend ActiveSupport::Concern

	  def is_gift_card_number_display(gift_card_number,client)
      if gift_card_number && client&.show_gift_card_number
        if client&.show_all_gift_card_digits
          return gift_card_number
        else
          return '*'*(gift_card_number.length - 4) + gift_card_number.chars.last(4).join
        end
      end
      return nil
    end
end
  