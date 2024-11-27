module Spree
  class Sitemap < Spree::Base
    has_one_attached :attachment, dependent: :purge_later
    belongs_to :store, :class_name => 'Spree::Store'
    
    def upload_to_aws file_path, file_name
      if File.exist?(file_path)
        self.attachment.purge_later if self.attachment.attached?
        unzip_gz(file_path, file_name)
        file = File.open(file_name)
        self.attachment.attach(io: file, filename: file_name)
        file.close()
        File.delete(file_name)
        self.save
      end
    end
  end
end
