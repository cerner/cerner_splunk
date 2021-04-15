require_relative "base"
require_relative "metadata_based_installer"

module CookbookOmnifetch
  # This location allows fetching from the `cookbook_artifacts/` API where Chef
  # Server stores cookbooks for policyfile use when they're uploaded via `chef push`.
  #
  # End users likely won't have much use for this; it's intended to facilitate
  # included policies when including a policy stored on a chef server and
  # cookbooks cannot be installed from the original source based on the
  # information in the included policy.
  class ChefServerArtifactLocation < BaseLocation

    attr_reader :cookbook_identifier
    attr_reader :uri

    def initialize(dependency, options = {})
      super
      @cookbook_identifier = options[:identifier]
      @http_client = options[:http_client] || default_chef_server_http_client
      @uri ||= options[:chef_server_artifact]
    end

    def repo_host
      @host ||= URI.parse(uri).host
    end

    def cookbook_name
      dependency.name
    end

    def url_path
      "/cookbook_artifacts/#{cookbook_name}/#{cookbook_identifier}"
    end

    def installer
      MetadataBasedInstaller.new(http_client: http_client, url_path: url_path, install_path: install_path)
    end

    def install
      installer.install
    end

    # Determine if this revision is installed.
    #
    # @return [Boolean]
    def installed?
      # Always force a refresh of cache
      false
    end

    def http_client
      @http_client
    end

    # The path where this cookbook would live in the store, if it were
    # installed.
    #
    # @return [Pathname, nil]
    def install_path
      @install_path ||= CookbookOmnifetch.storage_path.join(cache_key)
    end

    def lock_data
      { "chef_server_artifact" => uri, "identifier" => cookbook_identifier }
    end

    def cache_key
      "#{dependency.name}-#{cookbook_identifier}"
    end

    # @see BaseLocation#cached_cookbook
    def cached_cookbook
      @cached_cookbook ||= CookbookOmnifetch.cached_cookbook_class.from_path(install_path)
    end

    private

    def default_chef_server_http_client
      CookbookOmnifetch.default_chef_server_http_client
    end

  end
end
