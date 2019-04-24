# Need to write routines to read and convert manifest JSON files.

require 'json'
require 'optparse'
require 'pp'
require 'pathname'

def create_solr_doc(collection, file, package)
  filepath = file['filepath']
  sha1_tesig = file['sha1']
  size_lsi = file['size']

  # package_id is of form "urn:uuid:00112233-4455-6677-8899-aabbccddeeff"
  # this converts to a path prefix of "00/11/2233445566778899aabbccddeeff"

  urn = package['package_id']
  package_prefix = "#{urn[9..10]}/#{urn[11..12]}/#{urn[13..16]}#{urn[18..21]}#{urn[23..26]}#{urn[28..31]}#{urn[33..-1]}"

  fullpath_ssi = "#{package_prefix}/#{filepath}"

  all_locations = ((collection['locations'] || []) + (package['locations'] || []))
                  .map { |location| "#{location}/#{fullpath_ssi}" }

  id = Digest::MD5.hexdigest(fullpath_ssi)

  shares_ssim = []
  all_locations.each do |l|
    if /(?<share>archival\d\d)/ =~ l
      shares_ssim.push share
    end
  end

  {
    id: id,
    # collection-level stuff
    collection_ssi: collection['collection_id'],
    depositor_ssi: collection['depositor'],
    steward_ssi: (collection['steward'] || 'No collection steward'),
    rights_ssi: collection['rights'],
    # package-level stuff
    packageid_tesig: package['package_id'],
    bibid_ssi: (package['bibid'] || 'No bibid'),
    localid_ssi: (package['local_id'] || ' No local id'),
    shares_ssim: shares_ssim,
    # file-level stuff
    filepath_ssi: filepath,
    filename_ssi: File.basename(fullpath_ssi),
    fullpath_ssi: fullpath_ssi,
    sha1_tesig: sha1_tesig,
    size_lsi: size_lsi,

    location_ssm: all_locations
  }
end

namespace :manifest do
  desc 'Convert from old JSON format to new'
  task :convert do
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake manifest:convert -- [options]'
      opts.on('-m', '--manifest {jsonfile}', 'Old format JSON manifest', String) do |manifest|
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
    newmanifest['collection'] = depcollection

    coll = manifest[depcollection]
    newmanifest['steward']      = coll['steward']
    newmanifest['number_files'] = coll['number_files']
    newmanifest['locations']    = coll['locations'].map { |_k, v| v[0]['uri'] }
    newmanifest['files']        = []

    # The "items" key has path and file information.

    files = []
    items = coll['items']
    items.each do |path, dir|
      dir.each do |filename, filedata|
        files << {
          filename: filename,
          path: path,
          locations: [],
          bibid: filedata['bibid'],
          sha1: filedata['sha1'],
          md5: filedata['md5'],
          size: filedata['size']
        }
      end
    end
    newmanifest['files'] = files

    puts JSON.pretty_generate([newmanifest])
  end

  desc 'Convert from new JSON format to SOLR documents'
  task :solrize do
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake manifest:solrize -- [options]'
      opts.on('-m', '--manifest {jsonfile}', 'New format JSON manifest', String) do |manifest|
        options[:manifest] = manifest
      end
    end

    args = parser.order!(ARGV) {}
    parser.parse!(args)

    file = File.read(options[:manifest])
    # manifest consists of an array of collections

    solrdocs = []

    # TODO: Manifest is a single collection, not array of collections.
    # See https://github.com/cul-it/cular-metadata for details

    collection = JSON.parse(file)

    # Collection-level fields from manifest
    collection['packages'].each do |package|
      package['files'].each do |file|
        solrdocs << create_solr_doc(collection, file, package)
      end
    end

    puts JSON.pretty_generate(solrdocs)
  end

  desc 'Import SOLR documents into SOLR'
  task 'import' do
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: rake manifest:convert -- [options]'
      opts.on('-m', '--manifest {jsonfile}', 'Old format JSON manifest', String) do |manifest|
        options[:manifest] = manifest
      end
      opts.on('-u', '--url {solrUrl}', 'URL of SOLR index', String) do |url|
        options[:url] = url
      end
    end

    args = parser.order!(ARGV) {}
    parser.parse!(args)

    file = File.read(options[:manifest])
    manifest = JSON.parse(file)

    puts options[:url]

    solr = RSolr.connect url: options[:url]

    puts "uri: #{solr.uri}"
    puts "base_request_uri: #{solr.base_request_uri}"
    puts "base_uri: #{solr.base_uri}"

    # exit
    $stdout.sync = true
    manifest.each do |doc|
      solr.add doc
      print '.'
    end

    puts 'committing'
    solr.commit

    puts 'solr documents added.'
  end
end
