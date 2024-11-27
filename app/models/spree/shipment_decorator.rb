module Spree
  module ShipmentDecorator
    def self.included(base)
      base.include Spree::Webhooks::HasWebhooks
    end

    def self.prepended(base)
      base.belongs_to :vendor, class_name: "Spree::Vendor"
      base.has_one :fulfilment_info, class_name: "Spree::FulfilmentInfo"
      base.scope :gift_card_shipments, -> { where(delivery_mode: GIFT_CARD_TYPES)}
      base.scope :scheduled_shipments, ->(start_time, end_time) { where(card_generation_datetime: start_time..end_time)}
      base.scope :physical, -> { where(delivery_mode: PHYSICAL_TYPES)}
      base.after_create -> (shipment){ shipment.order.update_attribute(:updated_at, Time.now) }
      base.after_create -> { update_column(:fulfilment_status, 'fulfiled') unless delivery_mode.in?(['givex_physical', 'tsgift_physical']) }
      # shipment state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
        base.state_machine initial: :pending, use_transactions: false do
          event :acknowledged do
            transition from: %i(ready pending), to: :acknowledged, if: lambda { |shipment|
              shipment.order.paid? == true
            }
          end

          event :processing do
            transition from: :acknowledged, to: :processing, if: lambda { |shipment|
              shipment.order.paid? == true
            }
          end

          event :shipped do
            transition from: %i(ready pending acknowledged processing), to: :shipped, if: lambda { |shipment|
              shipment.order.paid? == true
            }
          end
          after_transition to: :shipped, do: :after_ship

          event :archived do
            transition from: :shipped, to: :archived
          end

          event :cancel do
            transition to: :canceled, from: %i(pending acknowledged processing dispatched archived)
          end
          after_transition to: :canceled, do: :after_cancel

          after_transition do |shipment, transition|
            shipment.state_changes.create!(
              previous_state: transition.from,
              next_state: transition.to,
              name: 'shipment'
            )
          end
        end

        base.whitelisted_ransackable_associations = %w[order]
        base.whitelisted_ransackable_attributes = ['number', 'state', 'vendor_id', 'delivery_pickup_date', 'delivery_pickup_time', 'card_generation_datetime','fulfilment_status']
    end

    def self.pickup_date_scope(date)
      where(delivery_pickup_date: DateTime.parse(date).beginning_of_day..DateTime.parse(date).end_of_day)
    end

    def self.ransackable_scopes(auth_object = nil)
      %i(completed_at_date_scope completed_at_gt_scope completed_at_lt_scope status_scope pickup_date_scope)
    end

    def all_digital?
      line_items.all?{ |s| DIGITAL_TYPES.include?s.delivery_mode}
    end

    def all_physical?
      line_items.all?{ |s| PHYSICAL_TYPES.include?s.delivery_mode}
    end

    def all_simple?
      line_items.all?{ |s| s.delivery_mode == "simple"}
    end

    def all_food?
      line_items.all?{ |s| FOOD_TYPES.include?s.delivery_mode}
    end

  end
end

::Spree::Shipment.prepend(Spree::ShipmentDecorator)
