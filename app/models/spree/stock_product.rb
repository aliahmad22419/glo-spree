class Spree::StockProduct < Spree::Product
  belongs_to :product_batch
  belongs_to :parent, class_name: "Spree::Product"

  after_commit :update_master_stock, if: :saved_change_to_count_on_hand?
  after_destroy -> { self.parent.reindex }
  
  scope :effective_at, -> (date = Date.today) { where(effective_date: date) }
  scope :effective, -> { where("effective_date >= ?", Date.today) }
  scope :expired, -> { where("effective_date < ?", Date.today) }

  private
  def update_master_stock
   self.master.stock_items.update_all(count_on_hand: self.count_on_hand)
  end
end