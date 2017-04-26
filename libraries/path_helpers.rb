# frozen_string_literal: true

module CernerSplunk
  # Helper methods for Splunk-related file and URL paths
  module PathHelpers
    # Provides constant defaults for Splunk's various default install directories based on platform and package.
    # Returned hash is nested by package and os. For example, `default_install_dirs[:splunk][:linux]` returns
    # the default directory for Splunk on Linux.
    #
    # Modifies default_install_dirs as provided by cerner_splunk_ingredient to use our current path scheme.
    #
    # @return [Hash] an index of default install directories for Splunk and the Universal Forwarder
    def self.cerner_default_install_dirs
      default_install_dirs.tap do |defaults|
        defaults[:splunk][:windows] = 'c:\Program Files\splunk'
        defaults[:universal_forwarder][:windows] = 'c:\Program Files\splunkforwarder'
      end
    end
  end
end
