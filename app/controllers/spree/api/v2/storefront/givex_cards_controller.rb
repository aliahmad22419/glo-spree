module Spree
  module Api
    module V2
      module Storefront
        class GivexCardsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:givex_request, :pdf_details]
          before_action :set_card, only: [:show, :send_email, :send_sms, :cancel_gift_cards]
          before_action :authorized_cs_lead, only: :cancel_gift_cards
          before_action :check_permissions
          before_action :authorize_client_store, only: :create

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            givex_cards = Spree::GivexCard.accessible_by(current_ability, :index).ransack(params[:q]).result.order("spree_givex_cards.created_at DESC")
            givex_cards = collection_paginator.new(givex_cards, params).call
            render_serialized_payload { serialize_collection(givex_cards) }
          end

          def create
            result = Spree::RegisterGivex.call(options: {
                                                id: params[:store_id].to_s + rand(1..10000).to_s,
                                                amount: params[:amount],
                                                store_id: params[:store_id]
                                              })

            if result&.success && result.value["result"].count > 5
              Spree::GivexCard.generete_and_send_email(result, params, current_client.id, spree_current_user&.id)
            else
              render_error_payload result&.success ? result.value.dig( "result", 2) : result.value and return
            end
            render_serialized_payload { success({response: 'GiveX Card Created Successfully'}) }
          end

          def show
            givex_pin = @card&.givex_transaction_reference&.split(':')[1]
            options = { card_number: @card.givex_number, card_pin: givex_pin }
            result = Spree::GivexBalance.call(options: options, store: @card&.store) if @card&.store.present?
            render_error_payload(result.value) and return unless result.success

            balance = result.present? ? result.value : @card.balance
            givex_number = @card.is_gift_card_number_display(@card.givex_number,@card.store.client)
            render json: {balance: balance, slug: @card.slug, number: givex_number, total_amount: @card.balance, currency: @card.currency.to_s,  customer_first_name: @card.customer_first_name, customer_last_name: @card.customer_last_name,
                          customer_email: @card.customer_email, receipient_phone_number: @card.receipient_phone_number, from_email: @card.from_email, currency_symbol: Spree::Money.new(@card&.currency)&.currency&.symbol,iso_code: @card.iso_code, order_number: @card&.order&.number}.to_json, status: 200
          end

          def pdf_details
            @bookkeeping_document = Spree::GivexCard.find_by(slug: params[:id]).bookkeeping_documents.create(template: 'giftcard')
            File.open(@bookkeeping_document.file_path, 'wb') { |f| f.puts @bookkeeping_document.render_pdf }
            send_data @bookkeeping_document.render_pdf, type: 'application/pdf', disposition: 'inline'
          end

          def send_email
            SesEmailsDataWorker.perform_async(@card.id, "digital_givex_card_recipient")
            render json: {}.to_json, status: 200
          end

          def send_sms
            SmsWorker.perform_async(@card&.store.id, params[:receipient_phone_number], "Spree::GivexCard", params[:slug])
            render json: {}.to_json, status: 200
          end

          def givex_request
            result = Spree::GivexApi.new(params, spree_current_store).givex_api
            render_serialized_payload { success({response: result}) } and return if result.success
            render_error_payload(result.value)
          end

          def givex_activate_card
            spree_store = Spree::Store.find_by('spree_stores.id = ?', params[:store])
            amount = params[:givex][:params][1]
            result = Spree::GivexApi.new(params[:givex], spree_store).givex_api
            render_error_payload(result.value) and return unless result.success

            Spree::GivexCard.active_card(params[:givex][:params][4],result.value,spree_store.id,current_client.id,amount,spree_store.default_currency,spree_current_user&.id) if result && result.value["result"][1] == '0'
            render_serialized_payload { success({response: result}) }
          end

          def cancel_gift_cards
            authorize! :cancel, Spree::GivexCard
            render_error_payload({success: false, error: I18n.t('spree.givex.not_storefront_card')}) unless @card.line_item.present?

            result = Spree::GivexApi.new(params, @card.line_item.store, {current_user: @spree_current_user, card: @card}).cancel_givex_api
            if result[:success]
              render_serialized_payload { success(result) }
            else
              render_error_payload(result)
            end
          end

          private
          def authorize_client_store
            render json: {error: "You are not authorized to create Givex Card for this Store."}, status: 403 unless current_client.store_ids.include?(params['store_id'].to_i)
          end

          def set_card
            @card = Spree::GivexCard.accessible_by(current_ability, :show).find_by('spree_givex_cards.id = ?', params[:id])
            return render json: {error: 'Unable to find givex card'}.to_json, status: 403 unless @card
          end
        end
      end
    end
  end
end
