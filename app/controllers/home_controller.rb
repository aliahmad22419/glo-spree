
class HomeController < ApplicationController
    layout 'application'

    def index
    end
    def sftp_login
        public_path = "#{Rails.root.to_s}/public"
        FileUtils.mkdir_p("#{public_path}/reports") unless Dir.exist?("#{public_path}/reports")
        FileUtils.rm_rf(Dir["#{public_path}/reports/downloads"]) if Dir.exist?("#{public_path}/reports/downloads")

        @filename = params[:filename]
        user = SftpUser.last

        unless user.email.eql?(params[:email]) && user.password.eql?(params[:password])
            @error_message = "Invalid email or password"
            render :sftp_login_form and return
        else
            @sftp_file = SftpFile.find_by('sftp_files.name = ?', @filename)
            @sftp_file.present? ? @file_url = Rails.application.routes.url_helpers.url_for(@sftp_file.attachment) : @error_message = "Invalid file name"
        end

        if @sftp_file.present?
            FileUtils.mkdir_p("#{public_path}/reports/downloads") unless Dir.exist?("#{public_path}/reports/downloads")
            file_path = "#{public_path}/reports/downloads/#{@filename}"

            url = @sftp_file.active_storge_url(@sftp_file.attachment)
            file = File.open(file_path, 'wb')
            file.write(open(url) {|f| f.read })
            file.close

            File.open(file_path, "r") do |f|
                send_data f.read, type: "application/#{@filename.split('.').last}", filename: @filename
                return
            end

            @filename = ''
        else
            @error_message = "Invalid file name"
            render :sftp_login_form
        end
    end
end
