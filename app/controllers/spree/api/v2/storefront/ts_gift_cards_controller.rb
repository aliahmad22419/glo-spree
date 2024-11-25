module Spree
  module Api
    module V2
      module Storefront
        class TsGiftCardsController < ::Spree::Api::V2::BaseController
          before_action :require_spree_current_user, except: [:pdf_details]
          before_action :check_permissions
          before_action :authorized_client_sub_client, except: [:cancel_gift_cards, :update_status]
          before_action :authorized_cs_lead, :set_ts_card, only: :cancel_gift_cards
          skip_before_action :unauthorized_frontdesk_user, only: :update_status


          def create
            params = request.params
            result = Spree::CreateTsgiftCard.new(params, current_client).create_card
            if result.code == 201
              result = result.parsed_response
              Spree::TsGiftcard.generete_and_send_sms(result, current_client)
              render_serialized_payload { success({success: true}) }
            else
              return render json: {errors: result.parsed_response["errors"] }, status: result.code if result.parsed_response["errors"].present?
              return render json: {errors: result.parsed_response.map { |key, value| "#{key}:#{value.join(",")}" }.join(", ")}, status: result.code
            end
          end

          def pdf_details
            @bookkeeping_document = Spree::TsGiftcard.find_by(slug: params[:id]).bookkeeping_documents.create(template: 'giftcard')
            File.open(@bookkeeping_document.file_path, 'wb') { |f| f.puts @bookkeeping_document.render_pdf }
            send_data @bookkeeping_document.render_pdf, type: 'application/pdf', disposition: 'inline'
          end

          def cancel_gift_cards
            authorize! :cancel, Spree::TsGiftcard
            render_error_payload({success: false, error: I18n.t('spree.ts_card.not_storefront_card')}) unless @ts_card.line_item.present?

            result = TsCurate::TsGiftCardService.new(@ts_card, params, {spree_current_user: @spree_current_user}).cancel_card

            if result[:success]
              render_serialized_payload { success(result) }
            else
              render_error_payload(result)
            end
          end

          def update_status
            authorize! :update_status, Spree::TsGiftcard
            ts_card = Spree::TsGiftcard.accessible_by(current_ability, :update_status).find_by('spree_ts_giftcards.id = ?', params[:id])

            if ts_card.present? && ts_card.update(status: params[:status])
              notes = "#{@spree_current_user.spree_roles.first.name.humanize} has #{params[:status]} the card"
              ts_card.history_logs.create(
                  kind: "card #{params[:status]}",
                  history_notes: params[:notes] || notes,
                  creator_email: @spree_current_user.email,
                  platform: @spree_current_user.spree_roles.first.name,
                  creator_id: @spree_current_user.id)
              render_serialized_payload { success({success: true}).value }
            else
              render_error_payload(I18n.t('spree.ts_card.not_found'))
            end
          end


          private

          def set_ts_card
            @ts_card = Spree::TsGiftcard.accessible_by(current_ability, :show).find_by('spree_ts_giftcards.id = ?', params[:id])
            return render json: {error: I18n.t('spree.ts_card.not_found')}.to_json, status: 404 unless @ts_card.present?
          end
        end
      end
    end
  end
end
