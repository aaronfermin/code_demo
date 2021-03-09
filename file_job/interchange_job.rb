#extension example

module Settlement
  class InterchangeJob < PropayFileJob
    def initialize
      super
      @file_name      = 'Qualifications'
      @cleanup_folder = 'Interchange Reports'
      @file_importer  = InterchangeImporter.new
    end
  end
end
