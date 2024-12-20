
module Spree
  module VendorDecorator
    def self.prepended(base)
      base.after_commit :reindex_to_elastic_stack
      base.extend FriendlyId
      base.friendly_id :friendly_url, slug_column: :landing_page_url, use: [:history, :scoped], scope: :id

      base.belongs_to :bill_address, foreign_key: :bill_address_id, class_name: 'Spree::Address', optional: true
      base.alias_method :billing_address, :bill_address

      base.belongs_to :ship_address, foreign_key: :ship_address_id, class_name: 'Spree::Address',
                optional: true
      base.belongs_to :vendor_group
      base.alias_method :shipping_address, :ship_address

      base.has_many :notifications_vendors, dependent: :destroy, :class_name => 'Spree::NotificationsVendor'
      base.has_many :notifications, dependent: :destroy, :through => :notifications_vendors
      base.has_many :questions, dependent: :destroy, :class_name => 'Spree::Question'
      base.has_one :image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
      base.has_one :banner_image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
      base.has_one :adyen_account, dependent: :destroy, class_name: 'Spree::AdyenAccount'
      base.has_many :line_items, class_name: 'Spree::LineItem'
      base.has_many :product_currency_prices, dependent: :destroy, :class_name => 'Spree::ProductCurrencyPrice'
      base.has_one :taxonomy, dependent: :destroy, class_name: 'Spree::Taxonomy'
      base.has_one :taxon, dependent: :destroy, class_name: 'Spree::Taxon'
      base.has_many :vendor_sale_analyses, class_name: 'Spree::VendorSaleAnalysis'

      base.validates :landing_page_url, uniqueness: { case_sensitive: false, scope: :client_id }
      base.validates :base_currency, presence: true, on: :update

      base.has_one :base_currency,
              -> { where("vendor_id IS NOT NULL")},
              class_name: 'Spree::Currency'


      base.whitelisted_ransackable_associations = %w[users]
      base.whitelisted_ransackable_attributes = %w[name sku state landing_page_url slug]

      # scope :active, -> { where("(spree_vendors.state != ?) AND (spree_vendors.vacation_mode IS NULL OR spree_vendors.vacation_mode = ?) AND ((spree_vendors.vacation_start IS NULL OR spree_vendors.vacation_start < ?) OR (spree_vendors.vacation_end IS NULL OR spree_vendors.vacation_end > ?))", 'blocked', false, Date.today, Date.today) }
      base.scope :active, -> { where("(spree_vendors.state != ?) AND (spree_vendors.vacation_mode IS NULL OR spree_vendors.vacation_mode = ?) AND spree_vendors.agreed_to_client_terms = ?",
                                'blocked', false, true) }
      base.scope :approved_vendors, -> { where("(spree_vendors.state != ?) AND (spree_vendors.vacation_mode IS NULL OR spree_vendors.vacation_mode = ?)", 'blocked', false) }
      base.scope :active_microsite, -> {where(microsite: true)}
      base.scope :not_pending, -> {where("spree_vendors.state != ?", 'pending')}
      base.scope :not_master, -> {where("spree_vendors.master = ?", false)}

      base.before_create :generate_sku_and_slug
      base.after_create :update_stock_location_propagate, :assign_base_currency
      base.after_create :create_taxonomy
      base.before_save :set_vacation_dates
      base.after_commit :clear_cache
    end

    def clear_cache
      self&.client&.stores&.each{|store| store.clear_store_cache()}
    end

    def friendly_url
      if landing_page_url.blank?
        o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
        string = (0...4).map { o[rand(o.length)] }.join
        name.parameterize + "-" + string
      else
        landing_page_url
      end
    end

    def should_generate_new_friendly_id?
      true
    end

    def set_vacation_dates
      if self.vacation_mode == false
        self.vacation_start = nil
        self.vacation_end = nil
      end
    end

    def normalize_friendly_id(value)
      value.to_s.parameterize(preserve_case: true)
    end

    def create_taxonomy
      Spree::Taxonomy.create(name: self&.name&.parameterize, vendor_id: self&.id, client_id: self&.client_id)
    end

    def create_stock_location
      stock_locations.where(name: name, country: shipping_address.present? ? shipping_address.country : Spree::Country.default, propagate_all_variants: false).first_or_create!
    end

    def update_stock_location_propagate
      stock_locations.where(name: name, country: shipping_address.present? ? shipping_address.country : Spree::Country.default, propagate_all_variants: false).first.update_column(:propagate_all_variants, true)
    end

    def generate_sku_and_slug
      o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
      string = (0...4).map { o[rand(o.length)] }.join
      self.sku = self.name.parameterize + '-' + string
      self.slug = self.sku + self.id.to_s
    end

    def email
      self.users.first.email if self.users.present?
    end

    def reindex_to_elastic_stack
      return unless (saved_change_to_name? || saved_change_to_sku? || saved_change_to_slug? || saved_change_to_local_store_ids?)
      if saved_change_to_local_store_ids?
        Searchkick.callbacks(:bulk) { products.find_each { |p| ProductPricesWorker.perform_async(p.id) } }
      else
        ReindexProductsWorker.perform_async(products.ids)
      end
    end

    def assign_base_currency
      return unless self.client.supported_currencies.present?

      currency = self.base_currency || self.build_base_currency
      currency.update(name: self.client.supported_currencies[0]) if currency.name.blank?
    end
  end
end

::Spree::Vendor.prepend Spree::VendorDecorator if ::Spree::Vendor.included_modules.exclude?(Spree::VendorDecorator)
