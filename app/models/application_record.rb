class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  self.abstract_class = true

  def active_storge_url(file)
    return "" unless file.attached?
    return Rails.application.routes.url_helpers.rails_public_blob_url(file)
  end

  def unzip_gz file_path, file_name
    if File.exist?(file_path)
      xml_file = File.open(file_name, 'w')
      gz_extract = Zlib::GzipReader.open(file_path)
      gz_extract.each_line { |extract| xml_file.write(extract) }
      xml_file.close
      gz_extract.close
    end
  end

  def local_date(date, timezone = 'UTC')
    date.present? ? date.in_time_zone(timezone) : nil
  end

  # Used only for ts bucket assets
  def get_s3_object_url key, format = 'png'
    return '#' if key.blank?

    "https://#{ENV['AWS_BUCKET_NAME']}.s3.amazonaws.com/#{key}#{format ? '.'+format : ''}"
  end

  def timezone_list
    ActiveSupport::TimeZone.all.each_with_object([]) do |timezone, obj|
      obj << {
        name: timezone.name,
        region: timezone.tzinfo.name,
        offset: Time.now.in_time_zone(timezone.tzinfo.name).formatted_offset
      }
    end.sort_by{ |tz| tz[:offset].to_f }
  end

  def update_preferences(preference_hash)
    return false if preference_hash.presence.nil?
    return unless self.respond_to?(:preferences) # check if preferences persists for the model

    preference_hash = preference_hash.to_unsafe_h unless preference_hash.is_a?(Hash)
    return unless preference_hash.present?

    forbidden = self.class.const_defined?(:FORBIDDEN_SET_PREFERENCES) ? self.class::FORBIDDEN_SET_PREFERENCES : []
    preference_hash.each { |k, v| set_preference(k, v) if has_preference?(k) && forbidden.exclude?(k.to_sym) }
    save!
  end

  def report_password(user=nil, password=ENV['ZIP_ENCRYPTION'])
    return password unless user.present?

    owner = if user.spree_roles.map(&:name).include?("vendor")
      user.vendors&.first
    elsif (["client", "sub_client"] & user.spree_roles.map(&:name)).present?
      user.client
    end

    owner.sales_report_password.presence || password
  end

  def type_of?(type=nil)
    self.class.name.demodulize.downcase  == type&.downcase
  end

end
