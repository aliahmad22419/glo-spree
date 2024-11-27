class SftpFile < ApplicationRecord
    has_one_attached :attachment

    def save_file_on_s3(file_path, file_name)
        if File.exist?(file_path)
          file = File.open(file_path)
          self.attachment.attach(io: file, filename: file_name)
          self.name = file_name
          self.object_key = self.attachment.key
          self.save
          file.close()
          File.delete(file_path)
          true
        end
    end
end
