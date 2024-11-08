class ProductBatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'batch_crud'

  def perform batch_id
    @product_batch = ProductBatch.find(batch_id)
    @product_batch.processing!
    @batch_schedule = @product_batch.batch_schedule
    @product = @product_batch.product
    create_scheduled_batch
  end

  private
  def create_scheduled_batch
    Spree::Product.transaction do
      begin
        build_stock_products
        @product.save!
        update_stock_items
        assign_variants if @product_batch.variants.present?
        @product_batch.completed!
      rescue => e
        rollback_batch(e.message)
      end
    end
  end

  def assign_variants
    #variants => [{option_value_ids, quantity, price, sku}]
    @product_batch.stock_products.each do |product| 
      @product_batch.variants.each do |variant|
        var = product.variants.new ({
                option_value_ids: variant["option_value_ids"],
                unit_cost_price: variant["unit_cost_price"],
                barcode_number: variant["barcode_number"],
                rrp: variant["rrp"],
                price: variant["price"],
                sku: variant["sku"]
              })
        var.save!
        stock_obj = var.stock_items.first
        if stock_obj && !product.linked
          stock_obj.count_on_hand = variant["quantity"]
          stock_obj.save
        end
      end
    end
  end

  def build_product_attributes
    @product.dup.attributes.merge! ({
      "option_type_ids" => @product_batch.option_type_ids,
      "count_on_hand" => product_quantity,
      "price" => @product_batch.product_price,
      "product_batch_id" => @product_batch.id,
      "name" => @product_batch.product_name,
      "store_ids" => @product.store_ids,
      "type" => "Spree::StockProduct",
      "daily_stock" => false,
      "disable_quantity" => false,
      "linked" => false
    })
  end

  def build_stock_products
    attributes = build_product_attributes
    @batch_schedule.effective_dates.each{ |effective_date|
      @product.stock_products.new attributes.merge! ({ 
        "effective_date" => effective_date
      })
    }
  end

  #parent product stock is not synchronized with daily stock
  def update_stock_items
    count_on_hand = product_quantity
    parent_count_on_hand = @product.count_on_hand
    @product_batch.stock_products.each do |product| 
      product.stock_items.first.update! count_on_hand: count_on_hand
      parent_count_on_hand+=count_on_hand
    end
    @product.update count_on_hand: parent_count_on_hand
  end

  def product_quantity
    product_batch_quantity = @product_batch.product_quantity.to_i 
    product_batch_quantity > 0 ? product_batch_quantity : 1
  end

  def rollback_batch(message = nil)
    @product_batch.update_column(:status, 'failed') 
    Rails.logger.error(message)
    raise ActiveRecord::Rollback 
  end
end  
