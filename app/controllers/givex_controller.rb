class GivexController < ApplicationController
    layout false
    before_action :current_store_without_redirection, except: [:show_external_ts_card]
    before_action :render_404_page, except: [:show_external_ts_card]
    before_action :set_givex_card, only: [:show_givex_card]
    before_action :set_ts_card, only: [:show_ts_card]
    before_action :set_ts_card_ex, only: [:show_external_ts_card]

    def show_givex_card
        @email_template_string = "No Template Found"
        html = @store&.email_templates&.find_by(email_type: "sms_digital_givex_recipient")&.html
        param_values = @givex_card&.generate_givex_data
        param_values&.stringify_keys!
        @email_template_string = html&.gsub(/\{\{(.*?)\}\}/) { |match| "#{param_values[$1.strip.tr "{{}}", '']} " } if html
    end

    def show_ts_card
        @email_template_string = "No Template Found"
        ts_response = JSON.parse(@ts_card.response)
        card_type = ts_response["value"]["card_type"]
        param_values = @ts_card.generate_ts_gift_card()
        param_values.stringify_keys!
        if card_type == "monetary"
            html = @store&.email_templates&.find_by(email_type: "sms_digital_ts_card_monetary_recipient")&.html
        elsif card_type == "experiences"
            html = @store&.email_templates&.find_by(email_type: "sms_digital_ts_card_experiences_recipient")&.html
        end
        @email_template_string = html.gsub(/\{\{(.*?)\}\}/) { |match| "#{param_values[$1.strip.tr "{{}}", '']} " } if html
    end

    def show_external_ts_card
        @email_template_string = "No Template Found"
        aws_client = Aws::SES::Client.new()
        begin
          aws_template = aws_client.get_template(template_name: "sms_campaign_#{ENV['SES_ENV']}_#{@ts_card.campaign_id}")
          html = aws_template.template.html_part
        rescue => e
          Rails.logger.error(e.message)
        end

        param_values = @ts_card&.generate_ts_gift_card_external
        param_values&.stringify_keys!
        @email_template_string = html.gsub(/\{\{(.*?)\}\}/) { |match| "#{param_values[$1.strip.tr "{{}}", '']} " } if html
    end

    private

    def set_givex_card
        (@givex_card = @store.givex_cards.find_by(slug: params[:id])) or render_not_found
    end

    def set_ts_card
        (@ts_card = @store.ts_giftcards.find_by(slug: params[:id])) or render_not_found
    end

    def set_ts_card_ex
        (@ts_card = Spree::TsGiftcard.without_store.find_by(slug: params[:id])) or render_not_found
    end
end
