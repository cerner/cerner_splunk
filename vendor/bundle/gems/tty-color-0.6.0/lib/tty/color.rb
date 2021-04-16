# frozen_string_literal: true

require_relative "color/mode"
require_relative "color/support"
require_relative "color/version"

module TTY
  # Responsible for checking terminal color support
  #
  # @api public
  module Color
    extend self

    NoValue = Module.new

    @verbose = false

    @output = $stderr

    attr_accessor :output, :verbose

    # Check if terminal supports colors
    #
    # @return [Boolean]
    #
    # @api public
    def support?
      Support.new(ENV, verbose: verbose).support?
    end
    alias supports? support?
    alias color? support?
    alias supports_color? support?

    # Detect if color support has been disabled with NO_COLOR ENV var.
    #
    # @return [Boolean]
    #   true when terminal color support has been disabled, false otherwise
    #
    # @api public
    def disabled?
      Support.new(ENV, verbose: verbose).disabled?
    end

    # Check how many colors this terminal supports
    #
    # @return [Integer]
    #
    # @api public
    def mode
      Mode.new(ENV).mode
    end

    # Check if output is linked with terminal
    #
    # @return [Boolean]
    #
    # @api public
    def tty?
      output.respond_to?(:tty?) && output.tty?
    end

    # Check if command can be run
    #
    # @return [Boolean]
    #
    # @api public
    def command?(cmd)
      !!system(cmd, out: ::File::NULL, err: ::File::NULL)
    end

    # Check if Windowz
    #
    # @return [Boolean]
    #
    # @api public
    def windows?
      ::File::ALT_SEPARATOR == "\\"
    end
  end # Color
end # TTY
