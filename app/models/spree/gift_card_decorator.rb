
module Spree
	module GiftCardDecorator

		def self.prepended(base)
			base.after_create :send_email_to_customer, if: proc { self.line_item }
			base.after_create :send_email_to_sender, if: proc { self.line_item }
		end

		def send_email_to_customer
			if self.line_item.order.store.ses_emails
				SesEmailsDataWorker.perform_async(self.id, "voucher_confirmation_recipient")
			else
				Spree::GeneralMailer.send_gift_card_cadentials_to_customer(self).deliver_now
			end
		end

		def send_email_to_sender
			SesEmailsDataWorker.perform_async(self.id, "voucher_confirmation_customer") if self.line_item.order.store.ses_emails
		end

		def set_values
			self.current_value = self.current_value.present? ? self.current_value : self.variant.try(:price)
			self.original_value = self.original_value.present? ? self.current_value : self.variant.try(:price)
		end

		def generate_code
			until self.code.present? && self.class.where(code: self.code).count == 0
				o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
				string = (0...9).map { o[rand(o.length)] }.join
				self.code = string + (Spree::GiftCard&.last.present? ? (Spree::GiftCard&.last&.id + 1) : 1).to_s
			end
		end
	end
end
Spree::GiftCard.prepend Spree::GiftCardDecorator
