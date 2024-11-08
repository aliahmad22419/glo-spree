module Spree
  module Scheduled
    class ReportGenerator
      include ScheduledSalesReport
      prepend Spree::ServiceModule::Base

      def initialize(report_id)
        @report = ScheduledReport.find(report_id)
        @client = @report.client_obj
        @request_time = nil
      end

      def generate
        return unless @report.present?

        ['sales_excluding_ppi', 'sales_including_ppi'].include?(@report.report_type) ? generate_sales_report : request_ts_report
      end

      def generate_sales_report
        @request_time = DateTime.now
        file_name = create_sales_report
        ScheduledReport.add_to_zip "./public/#{file_name}", @report.password
        res = upload_file_to_s3(file_name)
        if res[:success]
          @report.update_columns(report_link: res[:s3_file_url], report_link_updated_at: @request_time)
          SesEmailsScheduledReportWorker.perform_async(@report.id)
          rm_local_file(file_name)
        end

      end

      def request_ts_report
        begin
          @request_time = DateTime.now
          res = HTTParty.post(@report.client_obj.ts_url + '/api/v1/scheduled_reports', body: ts_request_body, basic_auth: basic_auth)
          res = JSON.parse(res.body)
          if res["success"]
            @report.update_columns(report_link: res["s3_file_url"], report_link_updated_at: @request_time)
            SesEmailsScheduledReportWorker.perform_async(@report.id)
          end
        rescue => e
          Rails.logger.error("Scheduled Report Error: #{e.message}")
          puts "Scheduled Report Error: #{e.message}"
        end
      end

      def ts_request_body
        start_date, end_date = determine_start_end_date
        ts_request_body = {
          id: @report.id,
          report_type: @report.report_type,
          fetch_from: start_date,
          password: @report.password,
          ts_store_ids: @report.ts_store_ids,
          timezone: @client.timezone,
          report_currency_code: @client.reporting_currency,
          report_currency_ex_rates: @client.reporting_currency_exchange_rates
        }
        ts_request_body[:end_date] = end_date if end_date.present?
        ts_request_body
      end

      def upload_file_to_s3(file_name)
        Spree::Scheduled::S3FileUploader.new(file_name).call
      end

      private

      def determine_start_end_date
        return [@report.beginning_of_start_date, @report.end_of_end_date] if @report.download_once?

        current_month_start = DateTime.now.beginning_of_month
        fetch_from = @report.preferred_fetch_from.eql?('last_generated_at') ? (@report.report_link_updated_at || current_month_start) : current_month_start
        [fetch_from, nil]
      end

      def basic_auth
        { username: @client.ts_email, password: @client.ts_password }
      end

      def rm_local_file(file_name)
        FileUtils.rm_rf("./public/#{file_name}.csv")
        FileUtils.rm_rf("./public/#{file_name}.zip")
      end
    end
  end
end
