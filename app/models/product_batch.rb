class ProductBatch < ApplicationRecord
  acts_as_paranoid

  enum status: { initialized: 0, processing: 1, completed: 2, failed: 3 }

  belongs_to :product, class_name: "Spree::Product"
  has_one :batch_schedule, as: :schedulable
  has_many :stock_products, class_name: "Spree::StockProduct", foreign_key: :product_batch_id
  accepts_nested_attributes_for :batch_schedule
  
  validate :validate_product_type
  after_create :process_job
  after_commit -> { product.reindex }, :assign_product_images, if: :completed?

  def process_job
    ProductBatchWorker.perform_async(id)
  end

  def assign_product_images
    BatchProductsImageWorker.perform_async(id)
  end

  private
  def validate_product_type
    errors.add(:product, "type must be daily stock") unless product&.daily_stock?
  end

end