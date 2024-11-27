module Spree
	module ZoneDecorator
		def self.prepended(base)
			base.validates :zone_code, uniqueness:  {  case_sensitive: false, allow_blank: false,
				conditions: -> { where(fulfilment_zone: true) }
			}, on: [:update, :create], if: -> { fulfilment_zone }

			base.after_commit :update_product_currency_prices
			base.has_and_belongs_to_many :stores, class_name: 'Spree::Store'
			base.has_and_belongs_to_many :fulfilment_teams, class_name: 'Spree::FulfilmentTeam'
			base.has_many :orders, class_name: "Spree::Order"

			base.scope :fulfilment_zone, -> { where(fulfilment_zone: true) }

			base.whitelisted_ransackable_attributes = %w[name zone_code]
			base.whitelisted_ransackable_associations = %w[ fulfilment_teams ]
		end

		def validate_unique_country_ids(params)
			common_countries = Spree::Zone.fulfilment_zone&.joins(:countries)&.where.not(id: id)&.pluck('spree_countries.id') & params[:country_ids].map(&:to_i)
			return Spree::Country.where(id: common_countries).pluck('name')
		end

		def self.match(address,fulfilment_zone=false)
			return unless address &&
				matches = includes(:zone_members).
							order('spree_zones.zone_members_count', 'spree_zones.created_at').
							where("(spree_zone_members.zoneable_type = 'Spree::Country' AND " \
								'spree_zone_members.zoneable_id = ?) OR ' \
								"(spree_zone_members.zoneable_type = 'Spree::State' AND " \
								'spree_zone_members.zoneable_id = ?)', address.country_id, address.state_id).
							references(:zones)

			matches = matches.where(fulfilment_zone: true) if fulfilment_zone
			%w[state country].each do |zone_kind|
				if match = matches.detect { |zone| zone_kind == zone.kind }
				return match
				end
			end
			matches.first
		end

		private

		def update_product_currency_prices
			return unless saved_change_to_default_tax?
			Searchkick.callbacks(:bulk) { client.products.find_each { |p| ProductPricesWorker.perform_async(p.id) } }
		end

		def remove_previous_default
			self.client.zones.with_default_tax.where.not(id: id).update_all(default_tax: false)
			Rails.cache.delete('default_zone')
		end
	end
end

::Spree::Zone.prepend Spree::ZoneDecorator if ::Spree::Zone.included_modules.exclude?(Spree::ZoneDecorator)
