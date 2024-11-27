module Spree
  class Gallery < Spree::Base
    has_one :image, as: :viewable, dependent: :destroy, class_name: 'Spree::Image'
    after_save :update_image
    belongs_to :client, :class_name => 'Spree::Client'

    self.whitelisted_ransackable_associations = %w[image]

    def self.supported_images
      joins(:image).where.not(
        "spree_assets.attachment_file_name LIKE ? OR
        spree_assets.attachment_file_name LIKE ? OR
        spree_assets.attachment_file_name LIKE ?
        ", '%.avif', '%.svg', '%.mp4')
        .select("spree_galleries.*, spree_assets.attachment_file_name")
        .order("spree_assets.attachment_file_name ASC")
    end

    def update_image
      if attachment_id.present? && attachment_id != image&.id
        image&.destroy
        img = Spree::Image.find(attachment_id)
        img.update_attribute :viewable_id, self.id
      end
    end
  end
end
