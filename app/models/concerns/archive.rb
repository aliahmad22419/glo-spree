module Archive
  extend ActiveSupport::Concern
  require 'archive/zip'

  def add_to_zip filename, password
    Archive::Zip.archive(
      "#{filename}.zip", "#{filename}.csv",
      :encryption_codec => lambda do |entry|
        if entry.file? and entry.zip_path =~ /\.csv$/ then
          Archive::Zip::Codec::TraditionalEncryption
        else
          Archive::Zip::Codec::NullEncryption
        end
      end, password: password
    )
  end
end
