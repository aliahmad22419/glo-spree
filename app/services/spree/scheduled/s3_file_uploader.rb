require "aws-sdk-s3"

module Spree
  module Scheduled
    class S3FileUploader
      attr_accessor :file_name

      def initialize(file_name)
        @file_name = "#{file_name}.zip"
      end

      def call
        upload_file
      end

      private

      def s3_object
        Aws::S3::Object.new(ENV['AWS_BUCKET_NAME'], file_name)
      end

      def upload_file
        begin
          s3_object.upload_file("./public/#{file_name}")
          {success: true, s3_file_url: "https://#{ENV['AWS_BUCKET_NAME']}.s3.amazonaws.com/#{file_name}"}
        rescue Aws::Errors::ServiceError => e
          Rails.logger.error("Couldn't upload file #{file_name}. Here's why: #{e.message}")
          {success: false}
        end
      end
    end
  end
end
