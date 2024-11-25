module Spree
  module Api
    module V2
      module Storefront
        class FulfilmentTeamController < ::Spree::Api::V2::BaseController
          include Spree::Api::V2

          before_action :require_spree_current_user
          before_action :set_fulfilment_team, except: [:index, :create, :team_orders, :download_fulfilment_report]
          before_action :set_report_orders, only: [:download_fulfilment_report]
          before_action :unauthorized_roles_except_fulfilment
          before_action :check_permissions

          def index
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            team = Spree::FulfilmentTeam.all.ransack(params[:q])&.result&.order("id DESC")
            team = collection_paginator.new(team, params).call
            render_serialized_payload { serialize_collection(team,Spree::V2::Storefront::FulfilmentTeamSerializer) }
          end

          def show
            render_serialized_payload { serialize_resource(@fulfilment_team,Spree::V2::Storefront::FulfilmentTeamSerializer) }
          end

          def update
            if @fulfilment_team.update(fulfilment_team_params)
              render_serialized_payload { serialize_resource(@fulfilment_team,Spree::V2::Storefront::FulfilmentTeamSerializer) }
            else
              render_error_payload(failure(@fulfilment_team,).error)
            end
          end

          def create
            team = Spree::FulfilmentTeam.new(fulfilment_team_params.merge({creator_id: spree_current_user.id}))
            if team.save
              render_serialized_payload { serialize_resource(team,Spree::V2::Storefront::FulfilmentTeamSerializer) }
            else
              render_error_payload(failure(team).error)
            end
          end

          def destroy
            if @fulfilment_team.destroy
              render_serialized_payload { serialize_resource(@fulfilment_team,Spree::V2::Storefront::FulfilmentTeamSerializer) }
            else
              render_error_payload(failure(@fulfilment_team).error)
            end
          end

          def team_orders
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])

            orders = Spree::Order.complete&.fulfilment_store_orders&.accessible_by(current_ability)&.includes(:zone, :store, :shipments)&.where(spree_shipments: { delivery_mode: ['givex_physical','tsgift_physical']})
            non_quarantine = params[:q].delete('order_tags_label_name_not_eq')
            orders = orders&.without_tag(non_quarantine) if non_quarantine.present?
            orders = orders&.ransack(params[:q])&.result(distinct: true)&.order("spree_orders.completed_at DESC")
            orders = collection_paginator.new(orders, params).call
            render_serialized_payload { serialize_collection(orders, Spree::V2::Storefront::FulfilmentOrderSerializer) }
          end

          def download_fulfilment_report
            filename = "fulfilment-orders-report-#{Date.today.to_s}"
            options = {
                fulfilment_infos: @fulfilment_infos,
                user:  @spree_current_user,
                method: :to_csv,
                filename: filename
            }
            archive = FulfilmentReport.send(:download_csv, options)
            send_file archive, type: 'application/zip', disposition: 'attachment'
          end

          private

          def set_report_orders
            params[:q] = JSON.parse(params[:q]) if params[:q].present? && valid_json?(params[:q])
            params[:q] = params[:q].merge(shipment_fulfilment_status_eq: 'fulfiled', shipment_delivery_mode_in: ['givex_physical', 'tsgift_physical'])
            @fulfilment_infos = Spree::FulfilmentInfo.store_fulfilment_infos.fulfiled.ransack(params[:q]).result.sorted_infos.uniq
          end

          def set_fulfilment_team
            @fulfilment_team = Spree::FulfilmentTeam.find_by('spree_fulfilment_teams.id = ?', params[:id])
          end

          def fulfilment_team_params
            params[:fulfilment_team].permit(:name, :code, :zone_ids=>[], :user_ids=>[])
          end

        end
      end
    end
  end
end
