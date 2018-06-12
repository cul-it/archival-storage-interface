# Need to write routines to read and convert manifest JSON files.

require 'json'
require 'optparse'
require 'pp'

namespace :manifest do

  desc "Convert from old JSON format to new"
  task :convert do
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: rake manifest:convert [options]"
      opts.on("-m", "--manifest {jsonfile}", "Old format JSON manifest", String) do |manifest|
        options[:manifest] = manifest
      end
    end

    args = parser.order!(ARGV) {}
    parser.parse!(args)
        
    file = File.read(options[:manifest])
    manifest = JSON.parse(file)

    # The sole key in the manifest should be the depositor/collection string

    depcollection = manifest.keys[0]

    # split it on last /, so a depositor collection of A/B/C should have depositor A/B, collection C

#    matchdata = /(.*)\/([^\/]*)/.match(depcollection)
#    (dep, coll) = matchdata[1,2]
#    pp dep
#    pp coll

    
    
    newmanifest = {}
    newmanifest["collection"] = depcollection

    coll = manifest[depcollection]
    newmanifest["steward"]      = coll["steward"]
    newmanifest["number_files"] = coll["number_files"]
    newmanifest["locations"]    = coll["locations"].map { |k,v| v[0]["uri"] }
    newmanifest["files"]        = []

    # The "items" key has path and file information.

    files = []
    items = coll["items"]
    items.each do | path, dir |
      file = {}
      dir.each do | filename, filedata |
        file["filename"] = filename
        file["path"] = path
        file["locations"] = []
        file["bibid"] = filedata["bibid"]
        file["sha1"] = filedata["sha1"]
        file["size"] = filedata["size"]
      end
      files.push file
    end
    newmanifest["files"] = files
      

    puts JSON.pretty_generate([newmanifest])
    
      

  end
end

    
