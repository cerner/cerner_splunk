require_relative "base"

require "mixlib/archive" unless defined?(Mixlib::Archive)
require "tmpdir" unless defined?(Dir.mktmpdir)

module CookbookOmnifetch

  class ArtifactserverLocation < BaseLocation

    attr_reader :uri
    attr_reader :cookbook_version

    def initialize(dependency, options = {})
      super
      @uri ||= options[:artifactserver]
      @cookbook_version = options[:version]
    end

    def repo_host
      @host ||= URI.parse(uri).host
    end

    def cookbook_name
      dependency.name
    end

    # Determine if this revision is installed.
    #
    # @return [Boolean]
    def installed?
      install_path.exist?
    end

    # Install the given cookbook. Subclasses that implement this method should
    # perform all the installation and validation steps required.
    #
    # @return [void]
    def install
      FileUtils.mkdir_p(cache_root) unless cache_root.exist?

      http = http_client(uri)
      http.streaming_request(nil) do |tempfile|
        tempfile.close
        FileUtils.mv(tempfile.path, cache_path)
      end

      FileUtils.mkdir_p(staging_root) unless staging_root.exist?
      Dir.mktmpdir(nil, staging_root) do |staging_dir|
        Mixlib::Archive.new(cache_path).extract(staging_dir, perms: false)
        staged_cookbook_path = File.join(staging_dir, cookbook_name)
        validate_cached!(staged_cookbook_path)
        FileUtils.mv(staged_cookbook_path, install_path)
      end
    end

    # TODO: DI this.
    def http_client(uri)
      Chef::HTTP::Simple.new(uri)
    end

    def sanitized_version
      cookbook_version
    end

    # The path where this cookbook would live in the store, if it were
    # installed.
    #
    # @return [Pathname, nil]
    def install_path
      @install_path ||= CookbookOmnifetch.storage_path.join(cache_key)
    end

    def cache_key
      "#{dependency.name}-#{cookbook_version}-#{repo_host}"
    end

    # The cached cookbook for this location.
    #
    # @return [CachedCookbook]
    def cached_cookbook
      raise AbstractFunction,
        "#cached_cookbook must be implemented on #{self.class.name}!"
    end

    def lock_data
      out = {}
      out["artifactserver"] = uri
      out["version"] = cookbook_version
      out
    end

    # The lockfile representation of this location.
    #
    # @return [string]
    def to_lock
      raise AbstractFunction,
        "#to_lock must be implemented on #{self.class.name}!"
    end

    # The path where all pristine tarballs from an artifactserver are held.
    # Tarballs are moved/swapped into this location once they have been staged
    # in a co-located staging directory.
    #
    # @return [Pathname]
    def cache_root
      Pathname.new(CookbookOmnifetch.cache_path).join(".cache", "artifactserver")
    end

    # The path where tarballs are downloaded to and unzipped.  On certain platforms
    # you have a better chance of getting an atomic move if your temporary working
    # directory is on the same device/volume as the  destination.  To support this,
    # we use a staging directory located under the cache path under the rather mild
    # assumption that everything under the cache path is going to be on one device.
    #
    # Do not create anything under this directory that isn't randomly named and
    # remember to release your files once you are done.
    #
    # @return [Pathname]
    def staging_root
      Pathname.new(CookbookOmnifetch.cache_path).join(".cache_tmp", "artifactserver")
    end

    # The path where the pristine tarball is cached
    #
    # @return [Pathname]
    def cache_path
      cache_root.join("#{cache_key}.tgz")
    end

  end
end
