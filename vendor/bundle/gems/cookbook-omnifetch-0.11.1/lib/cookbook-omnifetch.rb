require_relative "cookbook-omnifetch/version"
require_relative "cookbook-omnifetch/integration"

require_relative "cookbook-omnifetch/base"
require_relative "cookbook-omnifetch/git"
require_relative "cookbook-omnifetch/github"
require_relative "cookbook-omnifetch/path"
require_relative "cookbook-omnifetch/artifactserver"
require_relative "cookbook-omnifetch/artifactory"
require_relative "cookbook-omnifetch/chef_server"
require_relative "cookbook-omnifetch/chef_server_artifact"

module CookbookOmnifetch

  # Create a new instance of a Location class given dependency and options.
  # The type of class is determined by the values in the given +options+
  # Hash.
  #
  # If you do not provide an option with a matching location id, +nil+
  # is returned.
  #
  # @example Create a git location
  #   Location.init(dependency, git: 'git://github.com/berkshelf/berkshelf.git')
  #
  # @example Create a GitHub location
  #   Location.init(dependency, github: 'berkshelf/berkshelf')
  #
  # @param [Dependency] dependency
  # @param [Hash] options
  #
  # @return [~BaseLocation, nil]
  def self.init(dependency, options = {})
    if klass = klass_from_options(options) # rubocop: disable Lint/AssignmentInCondition
      klass.new(dependency, options)
    else
      nil
    end
  end

  # Location an executable in the current user's $PATH
  #
  # @return [String, nil]
  #   the path to the executable, or +nil+ if not present
  def self.which(executable)
    if File.file?(executable) && File.executable?(executable)
      executable
    elsif ENV["PATH"]
      path = ENV["PATH"].split(File::PATH_SEPARATOR).find do |p|
        File.executable?(File.join(p, executable))
      end
      path && File.expand_path(executable, path)
    end
  end

  # Returns the Integration object which configures Dependency Injection
  # classes for the library.
  # @return [String]
  def self.integration
    @integration ||= Integration.new
  end

  # Yields the Integration object which configures Dependency Injection
  # classes for the library.
  # @yield [String]
  # @see Integration
  def self.configure
    yield integration
  end

  # Returns the filepath to the location where data will be cached.
  # @return [String]
  def self.cache_path
    integration.cache_path
  end

  # Returns an Object (generally a class or module, but that's not required)
  # that responds to the #shell_out method to run an external command. The
  # shell_out method accepts a single string for the command to run, and
  # returns an object that responds to #success?, #stdout and #stderr.
  #
  # Note that this shell_out method should not raise errors automatically.
  #
  # @return [#shell_out]
  def self.shell_out_class
    integration.shell_out_class
  end

  # Returns an Object (generally a class, but not required) that respsonds to
  # #from_path and returns an object representing the cookbook. In berkshelf,
  # this would be a Berkshelf::CachedCookbook (inherits from
  # Ridley::Chef::Cookbook). The object returned by
  # `cached_cookbook_class.from_path(path)` is expected to respond to #version
  # and #cookbook_name
  #
  # @return [#from_path]
  def self.cached_cookbook_class
    integration.cached_cookbook_class
  end

  # Returns a pathname object representing the location where cookbooks are
  # cached.
  #
  # NOTE: In the original berks code, this is generally accessed via
  # Berkshelf.cookbook_store.storage_path
  #
  # @return [Pathname]
  def self.storage_path
    integration.storage_path
  end

  # Returns the number of threads that will be used when downloading cookbooks
  # from a Chef Server. The default is 1.
  #
  # NOTE: This should only be changed if the `http_client` passed in to a
  # ChefServerLocation or ChefServerArtifactLocation is thread-safe. In
  # particular, the `Chef::ServerAPI` class is NOT THREAD SAFE. Chef Client uses
  # thread-local storage to create one instance of `Chef::ServerAPI` per-thread
  # when used in threaded code.
  #
  # When a properly thread-safe HTTP client is used, this can be configured to
  # a larger value to reduce the time needed to download cookbooks from a Chef
  # Server.
  def self.chef_server_download_concurrency
    integration.chef_server_download_concurrency
  end

  def self.default_chef_server_http_client
    integration.default_chef_server_http_client
  end

  # Returns true or false if the given path contains a Chef Cookbook
  #
  # @param [#to_s] path
  #   path of directory to reflect on
  #
  # @return [Boolean]
  def self.cookbook?(path)
    File.exist?(File.join(path, "metadata.json")) || File.exist?(File.join(path, "metadata.rb"))
  end

  class << self
    private

    # Load the correct location from the given options.
    #
    # @return [Class, nil]
    def klass_from_options(options)
      options.each do |key, _|
        id = key.to_s.split("_").map(&:capitalize).join

        begin
          return CookbookOmnifetch.const_get("#{id}Location")
        rescue NameError; end
      end

      nil
    end
  end
end
