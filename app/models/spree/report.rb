module Spree
  class Report < Spree::Base
    has_one_attached :attachment
    belongs_to :store, :class_name => 'Spree::Store'
    belongs_to :client, :class_name => 'Spree::Client'
    scope :with_feed_type, ->(type) { where(feed_type: type) }

    def save_csv_file(file_path, file_name)
      if File.exist?(file_path)
        file = File.open(file_path)
        self.attachment.attach(io: file, filename: file_name)
        file.close()
        self.save
        File.delete(file_path)
      end
    end
  end
end
