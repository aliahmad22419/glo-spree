class UploadImageWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'upload_image'

  def perform image_id, thumnalis_data, variant_id
    img = Spree::Image.find(image_id)
    s3_image = open(File.join(ENV.fetch("CDN_HOST"), img.attachment.blob.key))
    dup_img = Spree::Image.new(viewable_type: "Spree::Variant", attachment_file_name: img.attachment_file_name, viewable_id: variant_id)
    dup_img.attachment.attach(io: s3_image, filename: img.attachment_file_name)
    # dup_img.update(small_image: thumnalis_data["small_image"].nil? ? false : thumnalis_data["small_image"], base_image: thumnalis_data["base_image"].nil? ? false : thumnalis_data["base_image"], thumbnail: thumnalis_data["thumbnail"].nil? ? false : thumnalis_data["thumbnail"], sort_order: thumnalis_data["sort_order"] , sort_order_info_product: (thumnalis_data["sort_order_info_product"].present? ? thumnalis_data["sort_order_info_product"] : dup_img.sort_order_info_product) , alt: thumnalis_data["alt"])
    dup_img.save!
  end
end
