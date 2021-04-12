require_relative "threaded_job_queue"
require "digest/md5"

module CookbookOmnifetch

  class MetadataBasedInstaller
    class CookbookMetadata

      FILE_TYPES = %i{
        resources
        providers
        recipes
        definitions
        libraries
        attributes
        files
        templates
        root_files
        all_files
      }.freeze

      def initialize(metadata)
        @metadata = metadata
      end

      def files(&block)
        FILE_TYPES.each do |type|
          next unless @metadata.key?(type.to_s)

          @metadata[type.to_s].each do |file|
            yield file["url"], file["path"], file["checksum"]
          end
        end
      end
    end

    attr_reader :http_client
    attr_reader :url_path
    attr_reader :install_path
    attr_reader :slug

    def initialize(http_client:, url_path:, install_path:)
      @http_client = http_client
      @url_path = url_path
      @install_path = install_path
      @slug = Kernel.rand(1_000_000_000).to_s
    end

    def install
      metadata = http_client.get(url_path)
      clean_cache(metadata)
      sync_cache(metadata)
    end

    # Removes files from cache that are not supposed to be there, based on
    # files in metadata.
    def clean_cache(metadata)
      actual_file_list = Dir.glob(File.join(install_path, "**/*"))
      expected_file_list = []
      CookbookMetadata.new(metadata).files { |_, path, _| expected_file_list << File.join(install_path, path) }

      extra_files = actual_file_list - expected_file_list
      extra_files.each do |path|
        if File.file?(path)
          FileUtils.rm(path)
        end
      end
    end

    # Downloads any out-of-date files into installer cache, overwriting
    # those that don't match the checksum provided the metadata @ url_path
    def sync_cache(metadata)
      queue = ThreadedJobQueue.new
      CookbookMetadata.new(metadata).files do |url, path, checksum|
        dest_path = File.join(install_path, path)
        FileUtils.mkdir_p(File.dirname(dest_path))
        if file_outdated?(dest_path, checksum)
          queue << lambda do |_lock|
            http_client.streaming_request(url) do |tempfile|
              tempfile.close
              FileUtils.mv(tempfile.path, dest_path)
            end
          end
        end
      end
      queue.process(CookbookOmnifetch.chef_server_download_concurrency)
    end

    # Check if a given file (at absolute path) is missing or does has a mismatched md5sum
    #
    # @return [TrueClass, FalseClass]
    def file_outdated?(path, expected_md5sum)
      return true unless File.exist?(path)

      md5 = Digest::MD5.new
      File.open(path, "r") do |file|
        while (chunk = file.read(1024))
          md5.update chunk
        end
      end
      md5.to_s != expected_md5sum
    end
  end
end
