# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

# Attachments associate records with blobs. Usually that's a one record-many blobs relationship,
# but it is possible to associate many different records with the same blob. If you're doing that,
# you'll want to declare with <tt>has_one/many_attached :thingy, dependent: false</tt>, so that destroying
# any one record won't destroy the blob as well. (Then you'll need to do your own garbage collecting, though).
class ActiveStorage::Attachment < ActiveRecord::Base
  self.table_name = "active_storage_attachments"

  belongs_to :record, polymorphic: true, touch: true
  belongs_to :blob, class_name: "ActiveStorage::Blob"

  delegate_missing_to :blob

  after_create_commit :analyze_blob_later, :identify_blob
  after_commit :create_variant_images

  attr_accessor :client_store_sizes

  # Synchronously purges the blob (deletes it from the configured service) and destroys the attachment.
  def purge
    blob.purge
    destroy
  end

  # Destroys the attachment and asynchronously purges the blob (deletes it from the configured service).
  def purge_later
    blob.purge_later
    destroy
  end

  private

  def create_variant_images
    if Rails.env.production? && (record.respond_to?(:viewable_type) && (record.viewable_type == "Spree::Variant" || record.viewable_type == "Spree::Vendor"))
      sizes = Spree::Image.styles.values
      if record.viewable_type == "Spree::Variant"
        product = record&.viewable&.product
        data = Spree::Store&.select("id, max_image_width,max_image_height")&.where(id: product&.store_ids).where("max_image_width IS NOT NULL AND max_image_height IS NOT NULL")
        sizes = sizes + data&.map{|store| store&.max_image_width&.to_s + "x" + store&.max_image_height&.to_s + ">"}
      end
      sizes.each{|s| self.variant(resize: s).processed}
    end
  end

  def identify_blob
    blob.identify
  end

  def analyze_blob_later
    blob.analyze_later unless blob.analyzed?
  end
end