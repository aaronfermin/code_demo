class SftpFileHelper < SftpHelper
  attr_accessor :remote_path, :local_path, :log_name

  def file_name(file)
    file.to_s.split('/').last
  end

  def download_remote_files(file_mask)
    files = get_file_list(file_mask)
    return unless found_files?(files)

    log "Begin download for file mask: #{file_mask}", color: :cyan
    files.each { |file_name| download_remote_file(file_name) }
    log "End download for file mask: #{file_mask}", color: :cyan
    close_sftp_connection
    files.count
  end

  def download_remote_file(file_name, close_connection: false)
    files = get_file_list(file_name)
    return unless found_files?(files)

    log "Downloading - #{file_name} to #{local_path}", color: :cyan
    try_sftp_action do
      store_file(file_name)
    end
    close_sftp_connection if close_connection
    files.count
  end

  def cleanup_remote_folder(folder, file_mask, close_connection: false)
    files = get_file_list(file_mask)
    return unless found_files?(files)

    log "Begin cleanup for file mask: #{file_mask}", color: :cyan
    files.each do |file_name|
      move_remote_file(folder, file_name)
    end
    log "End cleanup for file mask: #{file_mask}", color: :cyan
    close_sftp_connection if close_connection
  end

  def move_remote_file(folder, file_name, close_connection: false)
    return unless found_files?(get_file_list(file_name))

    cleanup_folder = "#{remote_path}/#{folder}"
    remote = "#{remote_path}/#{file_name}"
    cleanup = "#{cleanup_folder}/#{file_name}"
    log "Moving #{file_name} to #{cleanup_folder}", color: :cyan
    try_sftp_action do
      sftp.rename(remote, cleanup)
    end
    close_sftp_connection if close_connection
  end

  def get_file_list(file_mask = '*', close_connection: false)
    files = get_entries(file_mask, 'file')
    close_sftp_connection if close_connection
    files
  end

  def get_directory_list(directory_mask = '*', close_connection: false)
    directories = get_entries(directory_mask, 'directory')
    close_sftp_connection if close_connection
    directories
  end

  def get_symlink_list(symlink_mask = '*', close_connection: false)
    symlinks = get_entries(symlink_mask, 'symlink')
    close_sftp_connection if close_connection
    symlinks
  end

  def get_entries(mask, entry_type)
    msg = "Getting #{entry_type} list for #{remote_path}/#{mask}"
    log msg, color: :cyan
    filtered = []
    try_sftp_action do
      sftp.dir.entries(remote_path).each do |entry|
        next unless File.fnmatch(mask, entry.name)

        filtered.push entry.name if entry_type_matches?(entry_type, entry)
      end
    end
    filtered
  end

  def entry_type_matches?(entry_type, entry)
    case entry_type
    when 'file'
      return entry.file?
    when 'directory'
      return entry.directory?
    when 'symlink'
      return entry.symlink?
    else
      false
    end
  end

  def found_files?(files)
    return true if files&.any?

    log 'No files found', color: :yellow
    close_sftp_connection
    false
  end

  private

  def store_file(file_name)
    obj = S3_BUCKET.object("#{local_path}/#{file_name}")
    obj.put(
      body: sftp.download!("#{remote_path}/#{file_name}"),
      content_type: MiniMime.lookup_by_filename(file_name)&.content_type
    )
  end
end
