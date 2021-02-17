class PropayFileJob < TogetherworkJob
  attr_accessor :file_date, :file_name, :file_mask, :propay_helper,
                :file_importer, :file_exporter, :cleanup_folder

  def initialize
    super
    @file_date     = Time.current.strftime('%Y%m%d')
    @propay_helper = file_helper
  end

  def process
    files_downloaded = download_files if file_name
    run_file_processors if files_downloaded
  end

  def after_process
    cleanup_remote_directory if file_name && cleanup_folder
  end

  private

  def download_files
    propay_helper.download_remote_files(file_mask)
  end

  def cleanup_remote_directory
    cleanup_mask = "#{file_mask}.#{file_extension}"
    propay_helper.cleanup_remote_folder(cleanup_folder, cleanup_mask, close_connection: true)
  end

  def run_file_processors
    run_importer if file_importer
    run_exporter if file_exporter
  end

  def run_importer
    file_importer.start
  end

  def run_exporter
    file_exporter.start
  end

  def file_helper
    psfh = PropaySftpFileHelper.new
    psfh.log_name = log_name
    psfh.initialize_logger
    psfh
  end

  def file_extension
    return 'csv' unless file_name == '1099'

    'pdf'
  end

  def file_mask
    return "#{file_name}_#{file_date}_*" if file_name == '1099'

    "*_#{file_name}*#{file_date}*"
  end
end
