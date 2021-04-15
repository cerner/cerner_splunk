#
# Author:: Christopher Brown (<cb@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2009, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "time"
require "base64"
require "openssl/digest"
require "mixlib/authentication"
require "mixlib/authentication/digester"

module Mixlib
  module Authentication

    module SignedHeaderAuth

      NULL_ARG = Object.new

      ALGORITHM_FOR_VERSION = {
        "1.0" => "sha1",
        "1.1" => "sha1",
        "1.3" => "sha256",
      }.freeze()

      # Use of SUPPORTED_ALGORITHMS and SUPPORTED_VERSIONS is deprecated. Use
      # ALGORITHM_FOR_VERSION instead
      SUPPORTED_ALGORITHMS = ["sha1"].freeze
      SUPPORTED_VERSIONS = ["1.0", "1.1"].freeze

      DEFAULT_SIGN_ALGORITHM = "sha1".freeze
      DEFAULT_PROTO_VERSION = "1.0".freeze

      # === signing_object
      # This is the intended interface for signing requests with the
      # Opscode/Chef signed header protocol. This wraps the constructor for a
      # Struct that contains the relevant information about your request.
      #
      # ==== Signature Parameters:
      # These parameters are used to generate the canonical representation of
      # the request, which is then hashed and encrypted to generate the
      # request's signature. These options are all required, with the exception
      # of `:body` and `:file`, which are alternate ways to specify the request
      # body (you must specify one of these).
      # * `:http_method`: HTTP method as a lowercase symbol, e.g., `:get | :put | :post | :delete`
      # * `:path`: The path part of the URI, e.g., `URI.parse(uri).path`
      # * `:body`: An object representing the body of the request.
      #   Use an empty String for bodiless requests.
      # * `:timestamp`: A String representing the time in any format understood
      #   by `Time.parse`. The server may reject the request if the timestamp is
      #   not close to the server's current time.
      # * `:user_id`: The user or client name. This is used by the server to
      #   lookup the public key necessary to verify the signature.
      # * `:file`: An IO object (must respond to `:read`) to be used as the
      #   request body.
      # ==== Protocol Versioning Parameters:
      # * `:proto_version`: The version of the signing protocol to use.
      #   Currently defaults to 1.0, but version 1.1 is also available.
      # ==== Other Parameters:
      # These parameters are accepted but not used in the computation of the signature.
      # * `:host`: The host part of the URI
      def self.signing_object(args = {})
        SigningObject.new(args[:http_method],
                          args[:path],
                          args[:body],
                          args[:host],
                          args[:timestamp],
                          args[:user_id],
                          args[:file],
                          args[:proto_version],
                          args[:headers]
                         )
      end

      def algorithm
        ALGORITHM_FOR_VERSION[proto_version] || DEFAULT_SIGN_ALGORITHM
      end

      def proto_version
        DEFAULT_PROTO_VERSION
      end

      # Build the canonicalized request based on the method, other headers, etc.
      # compute the signature from the request, using the looked-up user secret
      #
      # @param rsa_key [OpenSSL::PKey::RSA] User's RSA key. If `use_ssh_agent` is
      #   true, this must have the public key portion populated. If `use_ssh_agent`
      #   is false, this must have the private key portion populated.
      # @param use_ssh_agent [Boolean] If true, use ssh-agent for request signing.
      def sign(rsa_key, sign_algorithm = algorithm, sign_version = proto_version, **opts)
        # Backwards compat stuff.
        if sign_algorithm.is_a?(Hash)
          # Was called like sign(key, sign_algorithm: 'foo', other: 'bar')
          opts.update(sign_algorithm)
          opts[:sign_algorithm] ||= algorithm
          opts[:sign_version] ||= sign_version
        else
          # Was called like sign(key, 'foo', '1.3', other: 'bar')
          Mixlib::Authentication.logger.warn("Using deprecated positional arguments for sign(), please update to keyword arguments (from #{caller[1][/^(.*:\d+):in /, 1]})") unless sign_algorithm == algorithm
          opts[:sign_algorithm] ||= sign_algorithm
          opts[:sign_version] ||= sign_version
        end
        sign_algorithm = opts[:sign_algorithm]
        sign_version = opts[:sign_version]
        use_ssh_agent = opts[:use_ssh_agent]

        digest = validate_sign_version_digest!(sign_algorithm, sign_version)
        # Our multiline hash for authorization will be encoded in multiple header
        # lines - X-Ops-Authorization-1, ... (starts at 1, not 0!)
        header_hash = {
          "X-Ops-Sign" => "algorithm=#{sign_algorithm};version=#{sign_version};",
          "X-Ops-Userid" => user_id,
          "X-Ops-Timestamp" => canonical_time,
          "X-Ops-Content-Hash" => hashed_body(digest),
        }

        signature = Base64.encode64(do_sign(rsa_key, digest, sign_algorithm, sign_version, use_ssh_agent)).chomp
        signature_lines = signature.split(/\n/)
        signature_lines.each_index do |idx|
          key = "X-Ops-Authorization-#{idx + 1}"
          header_hash[key] = signature_lines[idx]
        end

        Mixlib::Authentication.logger.trace "Header hash: #{header_hash.inspect}"

        header_hash
      end

      def validate_sign_version_digest!(sign_algorithm, sign_version)
        if ALGORITHM_FOR_VERSION[sign_version].nil?
          raise AuthenticationError,
            "Unsupported version '#{sign_version}'"
        end

        if ALGORITHM_FOR_VERSION[sign_version] != sign_algorithm
          raise AuthenticationError,
            "Unsupported algorithm #{sign_algorithm} for version '#{sign_version}'"
        end

        case sign_algorithm
        when "sha1"
          OpenSSL::Digest::SHA1
        when "sha256"
          OpenSSL::Digest::SHA256
        else
          # This case should never happen
          raise "Unknown algorithm #{sign_algorithm}"
        end
      end

      # Build the canonicalized time based on utc & iso8601
      #
      # ====Parameters
      #
      def canonical_time
        Time.parse(timestamp).utc.iso8601
      end

      # Build the canonicalized path, which collapses multiple slashes (/) and
      # removes a trailing slash unless the path is only "/"
      #
      # ====Parameters
      #
      def canonical_path
        p = path.gsub(/\/+/, "/")
        p.length > 1 ? p.chomp("/") : p
      end

      def hashed_body(digest = OpenSSL::Digest::SHA1)
        # This is weird. sign() is called with the digest type and signing
        # version. These are also expected to be properties of the object.
        # Hence, we're going to assume the one that is passed to sign is
        # the correct one and needs to passed through all the functions
        # that do any sort of digest.
        @hashed_body_digest = nil unless defined?(@hashed_body_digest)
        if !@hashed_body_digest.nil? && @hashed_body_digest != digest
          raise "hashed_body must always be called with the same digest"
        else
          @hashed_body_digest = digest
        end
        # Hash the file object if it was passed in, otherwise hash based on
        # the body.
        # TODO: tim 2009-12-28: It'd be nice to just remove this special case,
        # always sign the entire request body, using the expanded multipart
        # body in the case of a file being include.
        @hashed_body ||= if file && file.respond_to?(:read)
                           digester.hash_file(file, digest)
                         else
                           digester.hash_string(body, digest)
                         end
      end

      # Takes HTTP request method & headers and creates a canonical form
      # to create the signature
      #
      # ====Parameters
      #
      #
      def canonicalize_request(sign_algorithm = algorithm, sign_version = proto_version)
        digest = validate_sign_version_digest!(sign_algorithm, sign_version)
        canonical_x_ops_user_id = canonicalize_user_id(user_id, sign_version, digest)
        case sign_version
        when "1.3"
          [
            "Method:#{http_method.to_s.upcase}",
            "Path:#{canonical_path}",
            "X-Ops-Content-Hash:#{hashed_body(digest)}",
            "X-Ops-Sign:version=#{sign_version}",
            "X-Ops-Timestamp:#{canonical_time}",
            "X-Ops-UserId:#{canonical_x_ops_user_id}",
            "X-Ops-Server-API-Version:#{server_api_version}",
          ].join("\n")
        else
          [
            "Method:#{http_method.to_s.upcase}",
            "Hashed Path:#{digester.hash_string(canonical_path, digest)}",
            "X-Ops-Content-Hash:#{hashed_body(digest)}",
            "X-Ops-Timestamp:#{canonical_time}",
            "X-Ops-UserId:#{canonical_x_ops_user_id}",
          ].join("\n")
        end
      end

      def canonicalize_user_id(user_id, proto_version, digest = OpenSSL::Digest::SHA1)
        case proto_version
        when "1.1"
          # and 1.2 if that ever gets implemented
          digester.hash_string(user_id, digest)
        else
          # versions 1.0 and 1.3
          user_id
        end
      end

      # Parses signature version information, algorithm used, etc.
      #
      # ====Parameters
      #
      def parse_signing_description
        parts = signing_description.strip.split(";").inject({}) do |memo, part|
          field_name, field_value = part.split("=")
          memo[field_name.to_sym] = field_value.strip
          memo
        end
        Mixlib::Authentication.logger.trace "Parsed signing description: #{parts.inspect}"
        parts
      end

      def digester
        Mixlib::Authentication::Digester
      end

      # Low-level RSA signature implementation used in {#sign}.
      #
      # @api private
      # @param rsa_key [OpenSSL::PKey::RSA] User's RSA key. If `use_ssh_agent` is
      #   true, this must have the public key portion populated. If `use_ssh_agent`
      #   is false, this must have the private key portion populated.
      # @param digest [Class] Sublcass of OpenSSL::Digest to use while signing.
      # @param sign_algorithm [String] Hash algorithm to use while signing.
      # @param sign_version [String] Version number of the signing protocol to use.
      # @param use_ssh_agent [Boolean] If true, use ssh-agent for request signing.
      # @return [String]
      def do_sign(rsa_key, digest, sign_algorithm, sign_version, use_ssh_agent)
        string_to_sign = canonicalize_request(sign_algorithm, sign_version)
        Mixlib::Authentication.logger.trace "String to sign: '#{string_to_sign}'"
        case sign_version
        when "1.3"
          if use_ssh_agent
            do_sign_ssh_agent(rsa_key, string_to_sign)
          else
            raise AuthenticationError, "RSA private key is required to sign requests, but a public key was provided" unless rsa_key.private?
            rsa_key.sign(digest.new, string_to_sign)
          end
        else
          raise AuthenticationError, "Agent signing mode requires signing protocol version 1.3 or newer" if use_ssh_agent
          raise AuthenticationError, "RSA private key is required to sign requests, but a public key was provided" unless rsa_key.private?
          rsa_key.private_encrypt(string_to_sign)
        end
      end

      # Low-level signing logic for using ssh-agent. This requires the user has
      # already set up ssh-agent and used ssh-add to load in a (possibly encrypted)
      # RSA private key. ssh-agent supports keys other than RSA, however they
      # are not supported as Chef's protocol explicitly requires RSA keys/sigs.
      #
      # @api private
      # @param rsa_key [OpenSSL::PKey::RSA] User's RSA public key.
      # @param string_to_sign [String] String data to sign with the requested key.
      # @return [String]
      def do_sign_ssh_agent(rsa_key, string_to_sign)
        # First try loading net-ssh as it is an optional dependency.
        begin
          require "net/ssh"
        rescue LoadError => e
          # ???: Since agent mode is explicitly enabled, should we even catch
          # this in the first place? Might be cleaner to let the LoadError bubble.
          raise AuthenticationError, "net-ssh gem is not available, unable to use ssh-agent signing: #{e.message}"
        end

        # Try to connect to ssh-agent.
        begin
          agent = Net::SSH::Authentication::Agent.connect
        rescue Net::SSH::Authentication::AgentNotAvailable => e
          raise AuthenticationError, "Could not connect to ssh-agent. Make sure the SSH_AUTH_SOCK environment variable is set and ssh-agent is running: #{e.message}"
        end

        begin
          ssh2_signature = agent.sign(rsa_key.public_key, string_to_sign, Net::SSH::Authentication::Agent::SSH_AGENT_RSA_SHA2_256)
        rescue Net::SSH::Authentication::AgentError => e
          raise AuthenticationError, "Unable to sign request with ssh-agent. Make sure your key is loaded with ssh-add: #{e.class.name} #{e.message})"
        end

        # extract signature from SSH Agent response => skip first 20 bytes for RSA keys
        # "\x00\x00\x00\frsa-sha2-256\x00\x00\x01\x00"
        # (see http://api.libssh.org/rfc/PROTOCOL.agent for details)
        ssh2_signature[20..-1]
      end

      private :canonical_time, :canonical_path, :parse_signing_description, :digester, :canonicalize_user_id

    end

    # === SigningObject
    # A Struct-based value object that contains the necessary information to
    # generate a request signature. `SignedHeaderAuth.signing_object()`
    # provides a more convenient interface to the constructor.
    SigningObject = Struct.new(:http_method, :path, :body, :host,
                                     :timestamp, :user_id, :file, :proto_version,
                                     :headers) do

      include SignedHeaderAuth

      def proto_version
        (self[:proto_version] || SignedHeaderAuth::DEFAULT_PROTO_VERSION).to_s
      end

      def server_api_version
        key = (self[:headers] || {}).keys.select do |k|
          k.casecmp("x-ops-server-api-version") == 0
        end.first
        if key
          self[:headers][key]
        else
          DEFAULT_SERVER_API_VERSION
        end
      end
    end
  end
end
