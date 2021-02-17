class SftpHelper < TogetherworkJob
  attr_accessor :sftp_user, :sftp_password, :sftp_host, :sftp_connection

  def sftp
    create_sftp_connection unless @sftp_connection
    @sftp_connection
  end

  def try_sftp_action(num_attempts = 5)
    num_attempts.times do |attempt|
      msg = "SFTP action failed - Attempt #{attempt + 1}"
      log msg, color: :cyan if attempt.positive?
      begin
        yield
        break
      rescue Net::SSH::Exception => e
        log "Connection failed: #{e.message}", color: :red
      end
    end
  end

  def create_sftp_connection
    log 'Creating SFTP connection', color: :light_cyan
    try_sftp_action(100) do
      s = Net::SFTP.start(sftp_host, sftp_user, password: sftp_password)
      @sftp_connection = s
      log 'Connection created', color: :light_cyan
    end
  end

  def close_sftp_connection
    return if @sftp_connection.nil?

    log 'Closing SFTP connection', color: :light_cyan
    try_sftp_action do
      sftp.session.close
      log 'Connection closed', color: :light_cyan
    end
    @sftp_connection = nil
  end
end
