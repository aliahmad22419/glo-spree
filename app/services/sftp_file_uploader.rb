class SFTPFileUploader
    require 'net/sftp'
    require 'uri'

    attr_accessor :source_path

    def initialize(server_type)
      @server_type = server_type
      sftp_client
    end

    def upload_file!(source_path, destination_path)
        @client.upload("#{source_path}", "#{destination_path}")
    end

    def download_file(filename, path_to_download='./public/reports/SFTP_Downloads')
        Dir.mkdir(path_to_download) unless Dir.exist?(path_to_download)
        @client.download_file("./#{filename}","#{path_to_download}/#{filename}")
        return true
    end

    def disconnect
      @client.disconnect
    end

    private

    def sftp_client
      begin
        @client = SFTPClient.new(ENV["SFTP_#{@server_type}_HOST"], ENV["SFTP_#{@server_type}_USER"], password: ENV["SFTP_#{@server_type}_PSWD"])
        @client.connect
        return @client
      rescue => e
          return e.message
      end
    end
end

# SFTP client
class SFTPClient
  attr_accessor :host, :user, :password

  def initialize(host, user, password)
    @host = host
    @user = user
    @password = password
  end

  def connect
    sftp_client.connect!
  rescue Net::SSH::RuntimeError
    puts "Failed to connect to #{host}"
  end

  def disconnect
    sftp_client.close_channel
    ssh_session.close
  end

  def upload(local_path, remote_path)
    @sftp_client.upload!(local_path, remote_path)
    Rails.logger.debug("Uploaded to SFTP Location -> #{remote_path}")
  end

  def download_file(remote_path, local_path)
    @sftp_client.download!(remote_path, local_path)
    puts "Downloaded #{remote_path}"
  end

  def sftp_client
    @sftp_client ||= Net::SFTP::Session.new(ssh_session)
  end

  private

  def ssh_session
    @ssh_session ||= Net::SSH.start(host, user, password)
  end

end