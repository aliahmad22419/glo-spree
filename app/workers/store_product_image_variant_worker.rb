class StoreProductImageVariantWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'store_product_image_variant'

  def perform(resource_id, object_type = 'store', sizes = [])
    if object_type == 'store'
      store = Spree::Store.find(resource_id)
      sizes.push(store.max_image_width.to_s + "x" + store.max_image_height.to_s + ">")
      product_ids = store.products.ids
    else
      product = Spree::Product.find(resource_id)
      data = Spree::Store&.select("id, max_image_width,max_image_height")&.where(id: product&.store_ids).where("max_image_width IS NOT NULL AND max_image_height IS NOT NULL")
      sizes = sizes + data&.map{|store| store&.max_image_width&.to_s + "x" + store&.max_image_height&.to_s + ">"}
      product_ids = product.id
    end
    viewable_ids = Spree::Variant.where(product_id: product_ids).ids
    images = Spree::Image.where(viewable_id: viewable_ids)
    if images.present?
      images.each do |img|
        attachment = img.attachment
        next if attachment.blank?
        key_for_file = attachment.blob.key
        if ActiveStorage::Blob.service.exist?(key_for_file)
          begin
            sizes.each{|size| img.attachment.variant(resize: size).processed}
          rescue Exception => e
            
          end
        end
      end
    end
  end
end
