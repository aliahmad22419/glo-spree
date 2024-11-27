class Spree::FulfilmentInfo < Spree::Base
  REPLACEMENT_ATTRS = [:state, :replacement_id, :charged_by]
  enum info_type: {original: 0, replacement: 1}
  enum state: {pending: 0, processing: 1, fulfiled: 2}

  scope :store_fulfilment_infos, -> { joins(shipment: [order: :store]).where('spree_orders.completed_at >= spree_stores.fulfilment_start_date AND spree_orders.store_id = spree_stores.id AND spree_stores.allow_fulfilment = ?', true)}
  scope :sorted_infos, -> { order('created_at ASC') }
  scope :fulfiled, -> { where(state: 'fulfiled') }

  belongs_to :shipment, class_name: "Spree::Shipment"
	belongs_to :user, class_name: "Spree::User"
  belongs_to :original_info, class_name: 'Spree::FulfilmentInfo', foreign_key: 'original_id'
  has_many :replacements, class_name: 'Spree::FulfilmentInfo', foreign_key: 'original_id'
  has_one :replacement, class_name: 'Spree::FulfilmentInfo', foreign_key: 'replacement_id'
  has_one :order, through: :shipment

  validates :gift_card_number, presence: true
  validates :serial_number, presence: true
  validates :currency, presence: true
  validates :customer_shippment_paid, presence: true
  validates :processed_date, presence: true
  validates :postage_currency, presence: true
  validates :postage_fee, presence: true
  validates :receipt_reference, presence: true
  validates :courier_company, presence: true
  validates :tracking_number, presence: true
  validates :accurate_submition, presence: true
  validates :shipment_id, presence: true
  validates :user_id, presence: true

  before_create :set_replacement_id, if: proc { self.replacement? && self.original_info&.replacements&.any? }
  after_create :set_fulfilment_status, if: proc { self.original? }
  after_create :set_total_amount

  self.whitelisted_ransackable_associations = %w[replacements shipment]
  self.whitelisted_ransackable_attributes = ['processed_date', 'serial_number']

  def self.shipment_order_completed_at_gt(date)
    joins(:shipment).joins(:order).merge(Spree::Order.completed_at_gt_scope(date))
  end

  def self.shipment_order_completed_at_lt(date)
    joins(:shipment).joins(:order).merge(Spree::Order.completed_at_lt_scope(date))
  end

  def self.ransackable_scopes(auth_object = nil)
    [:shipment_order_completed_at_gt, :shipment_order_completed_at_lt]
  end

  REPLACEMENT_ATTRS.each do |column|
    define_method "replacement_#{column.to_s}?" do
      self.replacement_info[column.to_s]
    end
  end

  def replacement_fulfiled?
    if self.original?
      false
    elsif self.replacement?
      fulfiled?
    end
  end


  private

  def set_replacement_id
    self.replacement_id = self.original_info&.replacements&.sorted_infos&.last&.id
  end

  def set_fulfilment_status
    self.shipment.update_column(:fulfilment_status, :processing)
  end

  def set_total_amount
		items = self.shipment.line_items
		items.each(&:price_values)

		total_amount = items[0].tp(items.sum { |item| item.exchanged_prices[:amount].to_f }) rescue 0

    individual_card_values = Array.new
    items.each do |item|
      individual_card_values += ([eval(item.exchanged_prices[:sub_total])] * item.quantity)
    end

		quantity= items.sum(&:quantity)
		self.update_columns(amount: total_amount, quantity: quantity, each_card_value: individual_card_values.to_s[1..-2])
	end
end
