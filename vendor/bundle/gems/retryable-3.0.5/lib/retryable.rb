require 'retryable/version'
require 'retryable/configuration'
require 'forwardable'

# Runs a code block, and retries it when an exception occurs. It's great when working with flakey webservices (for example).
module Retryable
  class << self
    extend Forwardable

    # A Retryable configuration object. Must act like a hash and return sensible
    # values for all Retryable configuration options. See Retryable::Configuration.
    attr_writer :configuration

    # Call this method to modify defaults in your initializers.
    #
    # @example
    #   Retryable.configure do |config|
    #     config.contexts     = {}
    #     config.ensure       = proc {}
    #     config.exception_cb = proc {}
    #     config.log_method   = proc {}
    #     config.matching     = /.*/
    #     config.not          = []
    #     config.on           = StandardError
    #     config.sleep        = 1
    #     config.sleep_method = ->(seconds) { Kernel.sleep(seconds) }
    #     config.tries        = 2
    #   end
    def configure
      yield(configuration)
    end

    # The configuration object.
    # @see Retryable.configure
    def configuration
      @configuration ||= Configuration.new
    end

    delegate [:enabled?, :enable, :disable] => :configuration

    def with_context(context_key, options = {}, &block)
      unless configuration.contexts.key?(context_key)
        raise ArgumentError, "#{context_key} not found in Retryable.configuration.contexts. Available contexts: #{configuration.contexts.keys}"
      end
      retryable(configuration.contexts[context_key].merge(options), &block) if block
    end

    alias retryable_with_context with_context

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity
    def retryable(options = {})
      opts = configuration.to_hash

      check_for_invalid_options(options, opts)
      opts.merge!(options)

      # rubocop:disable Style/NumericPredicate
      return if opts[:tries] == 0
      # rubocop:enable Style/NumericPredicate

      on_exception = opts[:on].is_a?(Array) ? opts[:on] : [opts[:on]]
      not_exception = opts[:not].is_a?(Array) ? opts[:not] : [opts[:not]]

      matching = opts[:matching].is_a?(Array) ? opts[:matching] : [opts[:matching]]
      tries = opts[:tries]
      retries = 0
      retry_exception = nil

      begin
        opts[:log_method].call(retries, retry_exception) if retries > 0
        return yield retries, retry_exception
      rescue *not_exception
        raise
      rescue *on_exception => exception
        raise unless configuration.enabled?
        raise unless matches?(exception.message, matching)

        infinite_retries = :infinite || tries.respond_to?(:infinite?) && tries.infinite?
        raise if tries != infinite_retries && retries + 1 >= tries

        # Interrupt Exception could be raised while sleeping
        begin
          seconds = opts[:sleep].respond_to?(:call) ? opts[:sleep].call(retries) : opts[:sleep]
          opts[:sleep_method].call(seconds)
        rescue *not_exception
          raise
        rescue *on_exception
        end

        retries += 1
        retry_exception = exception
        opts[:exception_cb].call(retry_exception)
        retry
      ensure
        opts[:ensure].call(retries)
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity

    private

    def check_for_invalid_options(custom_options, default_options)
      invalid_options = default_options.merge(custom_options).keys - default_options.keys
      return if invalid_options.empty?
      raise ArgumentError, "[Retryable] Invalid options: #{invalid_options.join(', ')}"
    end

    def matches?(message, candidates)
      candidates.any? do |candidate|
        case candidate
        when String
          message.include?(candidate)
        when Regexp
          message =~ candidate
        else
          raise ArgumentError, ':matching must be a string or regex'
        end
      end
    end
  end
end
