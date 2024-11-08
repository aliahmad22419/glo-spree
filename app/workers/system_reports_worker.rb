class SystemReportsWorker
    include Sidekiq::Worker
    sidekiq_options queue: 'system_reports_queue'
    
    def perform
      ensure_local_folders
      yesterday_datetime

      @mutex = Mutex.new
      Thread.new do # Push to SFTP PROD server
        @sftp_server_type = 'PRD'
        generate_and_upload_reports
      end

      sleep 10.minutes
      Thread.new do # Push to SFTP CERT server
        @sftp_server_type = 'CERT'
        generate_and_upload_reports
      end
    end
    
    def sftp_uploader
      if @sftp_server_type.eql?('PRD')
        @prd_uploader ||= SFTPFileUploader.new('PRD')
      else
        @cert_uploader ||= SFTPFileUploader.new('CERT')
      end
    end

    def yesterday_datetime
      @report_datetime = 1.days.ago
    end

    def ensure_local_folders
      Dir.mkdir("./public/reports") unless Dir.exist?("./public/reports")
      Dir.mkdir("./public/reports/SFTP") unless Dir.exist?("./public/reports/SFTP")
      Dir.mkdir("./public/reports/SFTP_Downloads") unless Dir.exist?("./public/reports/SFTP_Downloads")
      FileUtils.rm_rf(Dir["./public/reports/SFTP/*"])
    end

    def generate_and_upload_reports      
      @mutex.synchronize do
        # upload_to_sftp(schedule: 'D', type: 'GiftCards')
        upload_to_sftp(schedule: 'D', type: 'Billing')

        if @report_datetime.at_end_of_month.to_date == @report_datetime.to_date
          upload_to_sftp(schedule: 'M', type: 'Billing')
          # upload_to_sftp(schedule: 'M', type: 'GiftCards')
        end

        sftp_uploader.disconnect
      end
    end

    def report_dates(daily)

      if daily.eql?('D')
        [@report_datetime.beginning_of_day, @report_datetime.end_of_day]
      else
        [@report_datetime.beginning_of_month, @report_datetime.end_of_month]
      end
    end

    def upload_to_sftp(schedule: 'D', type: 'Billing')
      prefix = schedule.eql?('M') ? "_M" : ""

      local_path = "./public/reports/SFTP/TechSembly_#{type}#{prefix}_#{@report_datetime.to_date.strftime("%Y%m%d")}"

      start_datetime, end_datetime = report_dates(schedule)
      options = {start_datetime: start_datetime, end_datetime: end_datetime, path: local_path}

      daily_report_file_path, total = if type.eql?('Billing')
        CsvReports.combined_sales_report(options)
      else
        # CsvReports.combined_cards_report(options)
      end

      sftp_file_name = local_path.split('/').last.split('.csv')[0]
      sftp_uploader.upload_file!("#{local_path}.csv", "./#{sftp_file_name}.dat")
      # upload sftp dat file to s3
      aws_dat_file = SftpFile.find_by(name: "#{local_path.split('/').last}.dat")
      unless aws_dat_file.present?
      dat_file = SftpFile.new(name: "#{local_path.split('/').last}.dat")
      Rails.logger.debug("#{dat_file.name} uploaded to S3") if dat_file.save_file_on_s3("#{local_path}.csv", dat_file.name)
      end
      file_data = "#{@report_datetime.strftime("%Y%m%d")}#{"0"*(10-total.to_s.length)}#{total}"
      upload_aud_file(file_data, local_path)
      Rails.logger.debug("Uploading to SFTP: (#{@sftp_server_type}) ./#{local_path.split('/').last}")
    end

    def upload_aud_file(file_data, path)
      aud_file = File.new("#{path}.txt", "w");
      aud_file.syswrite(file_data);
      aud_file.close();
      sftp_file_name = path.split('/').last.split('.csv')[0]
      sftp_uploader.upload_file!("#{path}.txt", "./#{sftp_file_name}.aud")
      # upload sftp aud file to s3
      aws_aud_file = SftpFile.find_by(name: "#{path.split('/').last}.aud")
      unless aws_aud_file.present?
        aud_file = SftpFile.new(name: "#{path.split('/').last}.aud")
        Rails.logger.debug("#{aud_file.name} uploaded to S3") if aud_file.save_file_on_s3("#{path}.txt", aud_file.name)
      end
      Rails.logger.debug("Uploaded to SFTP: (#{@sftp_server_type}) ./#{path.split('/').last}.aud")
    end
    
  end