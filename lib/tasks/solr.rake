# The solr_wrapper rake tasks don't quite do what I need them to do --
# specifically, start solr with the right collection data -- so I need
# to create my own versions here. Either that, or edit the gems.

require 'solr_wrapper'

namespace :bl do
  desc "Load the solr options and solr instance"
  task :environment do
    @solr_instance = SolrWrapper.instance
  end

  desc 'start solr with default collection'
  task start: :environment do
    begin
      @solr_instance.start
      @solr_instance.with_collection({}){}
    rescue => e
      if e.message.include?("Port #{@solr_instance.port} is already beign used by another process")
        puts "FAILED. Port #{@solr_instance.port} is already being used."
      else
        raise "Failed to start solr. #{e.class}: #{e.message}"
      end
    end
  end
end
