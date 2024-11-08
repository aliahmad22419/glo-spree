class BrimReportTransactionWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'brim_report', retry: 3

  def perform
    ensure_local_folders
    #our system zone is UTC and CT is 5 hours behind from UTC. Mean When our cron jobs run it will be 5AM for next day. That's why I am using yserterday to to
    @report_datetime = 1.days.ago.strftime('%Y%m%d')
    filename = "./public/reports/SFTP/Brim/TechSembly_Billing_#{@report_datetime}.csv"

    headers = [
      "Line item ID", "Client ID", "Storefront ID", "External Vendor ID", "Vendor ID", "Product ID",
      "Product Title", "Transaction Date", "Transaction Type", "Original Order Date",
      "Order Number", "Product Type", "Quantity", "Order Currency Code", "Order Subtotal",
      "Tax Exclusive", "Tax Inclusive", "Shipping Amount", "Discount Amount", "Refund Amount",
      "Refund Product Type", "Order Payment Method", "Stripe Transaction ID", "Card Type",
      "Card Country", "Shipping Method", "Gift Card Type", "GC Serial Number",
      "B2B - B2C", "Activation Date"
    ]
    transaction_records = Reports::BrimReportTransactionService.new.call()
    CSV.open(filename, 'w', write_headers: true, headers: headers) do |csv|
      transaction_records.each do |record|
        row = headers.map { |header| record.fetch(header, '') }
        csv << row
      end
    end
    @records_length = transaction_records.count
    upload_to_sftp
  end

  private

  # def send_to_sftp
    # upload_to_sftp
    # @mutex = Mutex.new
    # Thread.new do # Push to SFTP PROD server
    #   @sftp_server_type = 'PRD'
    #   upload_to_sftp
    # end

    # sleep 10.minutes
    # Thread.new do # Push to SFTP CERT server
    #   @sftp_server_type = 'CERT'
    #   upload_to_sftp
    # end
  # end

  def ensure_local_folders
    FileUtils.mkdir_p("./public/reports/SFTP/Brim") unless Dir.exist?("./public/reports/SFTP/Brim")
    FileUtils.rm_rf(Dir["./public/reports/SFTP/Brim/*"])
  end

  def upload_to_sftp
    local_path = "./public/reports/SFTP/Brim/TechSembly_Billing_#{@report_datetime}"
    sftp_file_name = local_path.split('/').last.split('.csv')[0]
    sftp_uploader.upload_file!("#{local_path}.csv", "./#{sftp_file_name}.dat")
    file_data = "#{sftp_file_name} | #{"0" * (10 - @records_length.to_s.length)}#{@records_length}"
    upload_aud_file(file_data, local_path)
    sftp_uploader.disconnect
    Rails.logger.debug("Uploading to SFTP: (#{@sftp_server_type}) ./#{local_path.split('/').last}")
  end

  def upload_aud_file(file_data, path)
    aud_file = File.new("#{path}.txt", "w");
    aud_file.syswrite(file_data);
    aud_file.close();
    sftp_file_name = path.split('/').last.split('.csv')[0]
    sftp_uploader.upload_file!("#{path}.txt", "./#{sftp_file_name}.aud")
    Rails.logger.debug("Uploaded to SFTP: (#{@sftp_server_type}) ./#{path.split('/').last}.aud")
  end

  def sftp_uploader
    SFTPFileUploader.new("TEST")
  end
end
