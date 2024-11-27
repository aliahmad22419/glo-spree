module Spree
  class Tag < ActsAsTaggableOn::Tag
    belongs_to :client, class_name: 'Spree::Client'
    before_destroy :safe_to_destroy?, prepend: true
    
    def validates_name_uniqueness?
      self.client.tags.find_by_name(name).present?
    end

    private
    
    def safe_to_destroy?
      if taggings.any?
        self.errors.add(:base, "Product Tag can't be deleted because, tag is associcated to product(s)")
        throw :abort
      end
    end
  end
end
  