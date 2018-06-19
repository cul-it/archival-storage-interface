# Need to write routines to read and convert manifest JSON files.

require 'json'
require 'optparse'
require 'pp'

namespace :manifest do

  desc "Convert from old JSON format to new"
  task :convert do
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: rake manifest:convert -- [options]"
      opts.on("-m", "--manifest {jsonfile}", "Old format JSON manifest", String) do |manifest|
        options[:manifest] = manifest
      end
    end

    args = parser.order!(ARGV) {}
    parser.parse!(args)
        
    file = File.read(options[:manifest])
    manifest = JSON.parse(file)

    # the "collection" key has both the depositor and collection
    depcollection = manifest.keys[0]
    
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
      dir.each do | filename, filedata |
        files << {
          filename: filename,
          path: path,
          locations: [],
          bibid: filedata["bibid"],
          sha1: filedata["sha1"],
          size: filedata["size"],
        }
      end
     end
    newmanifest["files"] = files
      

    puts JSON.pretty_generate([newmanifest])
  end

  desc "Convert from new JSON format to SOLR documents"
  task :solrize do
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: rake manifest:solrize -- [options]"
      opts.on("-m", "--manifest {jsonfile}", "New format JSON manifest", String) do |manifest|
        options[:manifest] = manifest
      end
    end

    args = parser.order!(ARGV) {}
    parser.parse!(args)

    file = File.read(options[:manifest])
    manifest = JSON.parse(file)

    # manifest consists of an array of collections

    solrdocs = []

    manifest.each do |collection|

      # the "collection" key has both the depositor and collection
      depcollection = collection["collection"]

      # split it on last /, so a depositor collection of A/B/C should have depositor A/B, collection C
      matchdata = /(.*)\/([^\/]*)/.match(depcollection)
      (depositor_tesi, collection_tesi) = matchdata[1,2]

      phys_coll_id_tesi = collection["phys_coll_id"] || "No physical collection"
      steward_tesi = collection["steward"] || "No collection steward"
      collection_locations = collection["locations"]

      files = collection["files"]

      files.each do |file|
        filename_ssi = file["filename"]
        fullpath_ssi = file["path"] + "/" + filename_ssi
        location_ssm = collection_locations + (file["locations"] || [])
        partOf_tesi = file["partOf"]
        bibid_ssi = file["bibid"]
        rmcmediano_ssi = file["rmcmediano"]
        sha1_tesig = file["sha1"]
        md5_tesig = file["md5"]
        size_lsi = file["size"]

        rawid = "#{depcollection}/#{fullpath_ssi}"
        id = Digest::MD5.hexdigest(rawid)

        type_tesi = filename_ssi[-3..-1] || filename_ssi

        # now put it into a solr document

        solr = {
          id: id,

          depositor_tesi: depositor_tesi,
          collection_tesi: collection_tesi,
          phys_coll_id_tesi: phys_coll_id_tesi,
          steward_tesi: steward_tesi,
          filename_ssi: filename_ssi,
          fullpath_ssi: fullpath_ssi,
          location_ssm: location_ssm,
          partOf_tesi: partOf_tesi,
          bibid_ssi: bibid_ssi,
          rmcmediano_ssi: rmcmediano_ssi,
          sha1_tesig: sha1_tesig,
          md5_tesig: md5_tesig,
          size_lsi: size_lsi,
          type_tesi: type_tesi
        }

        solrdocs << solr

      end
    end

    puts JSON.pretty_generate(solrdocs)
  end
           
end

    
