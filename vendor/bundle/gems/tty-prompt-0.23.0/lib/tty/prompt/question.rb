# frozen_string_literal: true

require_relative "converters"
require_relative "evaluator"
require_relative "question/modifier"
require_relative "question/validation"
require_relative "question/checks"
require_relative "utils"

module TTY
  # A class responsible for shell prompt interactions.
  class Prompt
    # A class responsible for gathering user input
    #
    # @api public
    class Question
      include Checks

      UndefinedSetting = Class.new do
        def to_s
          "undefined"
        end
        alias_method :inspect, :to_s
      end

      # Store question message
      # @api public
      attr_reader :message

      attr_reader :modifier

      attr_reader :validation

      # Initialize a Question
      #
      # @api public
      def initialize(prompt, **options)
        # Option deprecation
        if options[:validation]
          warn "[DEPRECATION] The `:validation` option is deprecated. Use `:validate` instead."
          options[:validate] = options[:validation]
        end

        @prompt       = prompt
        @prefix       = options.fetch(:prefix) { @prompt.prefix }
        @default      = options.fetch(:default) { UndefinedSetting }
        @required     = options.fetch(:required) { false }
        @echo         = options.fetch(:echo) { true }
        @in           = options.fetch(:in) { UndefinedSetting }
        @modifier     = options.fetch(:modifier) { [] }
        @validation   = options.fetch(:validate) { UndefinedSetting }
        @convert      = options.fetch(:convert) { UndefinedSetting }
        @active_color = options.fetch(:active_color) { @prompt.active_color }
        @help_color   = options.fetch(:help_color) { @prompt.help_color }
        @error_color  = options.fetch(:error_color) { :red }
        @value        = options.fetch(:value) { UndefinedSetting }
        @quiet        = options.fetch(:quiet) { @prompt.quiet }
        @messages     = Utils.deep_copy(options.fetch(:messages) { {} })
        @done         = false
        @first_render = true
        @input        = nil

        @evaluator = Evaluator.new(self)

        @evaluator << CheckRequired
        @evaluator << CheckDefault
        @evaluator << CheckRange
        @evaluator << CheckValidation
        @evaluator << CheckModifier
        @evaluator << CheckConversion
      end

      # Stores all the error messages displayed to user
      # The currently supported messages are:
      #  * :range?
      #  * :required?
      #  * :valid?
      attr_reader :messages

      # Retrieve message based on the key
      #
      # @param [Symbol] name
      #   the name of message key
      #
      # @param [Hash] tokens
      #   the tokens to evaluate
      #
      # @return [Array[String]]
      #
      # @api private
      def message_for(name, tokens = nil)
        template = @messages[name]
        if template && !template.match(/\%\{/).nil?
          [template % tokens]
        else
          [template || ""]
        end
      end

      # Call the question
      #
      # @param [String] message
      #
      # @return [self]
      #
      # @api public
      def call(message = "", &block)
        @message = message
        block.call(self) if block
        @prompt.subscribe(self) do
          render
        end
      end

      # Read answer and convert to type
      #
      # @api private
      def render
        @errors = []
        until @done
          result = process_input(render_question)
          if result.failure?
            @errors = result.errors
            @prompt.print(render_error(result.errors))
          else
            @done = true
          end
          question    = render_question
          input_line  = question + result.value.to_s
          total_lines = @prompt.count_screen_lines(input_line)
          @prompt.print(refresh(question.lines.count, total_lines))
        end
        @prompt.print(render_question) unless @quiet
        result.value
      end

      # Render question
      #
      # @return [String]
      #
      # @api private
      def render_question
        header = []
        if !Utils.blank?(@prefix) || !Utils.blank?(message)
          header << "#{@prefix}#{message} "
        end
        if !echo?
          header
        elsif @done
          header << @prompt.decorate(@input.to_s, @active_color)
        elsif default? && !Utils.blank?(@default)
          header << @prompt.decorate("(#{default})", @help_color) + " "
        end
        header << "\n" if @done
        header.join
      end

      # Decide how to handle input from user
      #
      # @api private
      def process_input(question)
        @input = read_input(question)
        if Utils.blank?(@input)
          @input = default? ? default : nil
        end
        @evaluator.(@input)
      end

      # Process input
      #
      # @api private
      def read_input(question)
        options = { echo: echo }
        if value? && @first_render
          options[:value] = @value
          @first_render = false
        end
        @prompt.read_line(question, **options).chomp
      end

      # Handle error condition
      #
      # @return [String]
      #
      # @api private
      def render_error(errors)
        errors.reduce([]) do |acc, err|
          acc << @prompt.decorate(">>", :red) + " " + err
          acc
        end.join("\n")
      end

      # Determine area of the screen to clear
      #
      # @param [Integer] lines
      #   number of lines to clear
      #
      # @return [String]
      #
      # @api private
      def refresh(lines, lines_to_clear)
        output = []
        if @done
          if @errors.count.zero?
            output << @prompt.cursor.up(lines)
          else
            lines += @errors.count
            lines_to_clear += @errors.count
          end
        else
          output << @prompt.cursor.up(lines)
        end
        output.join + @prompt.clear_lines(lines_to_clear)
      end

      # Convert value to expected type
      #
      # @param [Object] value
      #
      # @api private
      def convert_result(value)
        if convert? && !Utils.blank?(value)
          case @convert
          when Proc
            @convert.call(value)
          else
            Converters.convert(@convert, value)
          end
        else
          value
        end
      end

      # Specify answer conversion
      #
      # @api public
      def convert(value = (not_set = true), message = nil)
        messages[:convert?] = message if message
        if not_set
          @convert
        else
          @convert = value
        end
      end

      # Check if conversion is set
      #
      # @return [Boolean]
      #
      # @api public
      def convert?
        @convert != UndefinedSetting
      end

      # Set default value.
      #
      # @api public
      def default(value = (not_set = true))
        return @default if not_set

        @default = value
      end

      # Check if default value is set
      #
      # @return [Boolean]
      #
      # @api public
      def default?
        @default != UndefinedSetting
      end

      # Ensure that passed argument is present or not
      #
      # @return [Boolean]
      #
      # @api public
      def required(value = (not_set = true), message = nil)
        messages[:required?] = message if message
        return @required if not_set

        @required = value
      end
      alias required? required

      # Set validation rule for an argument
      #
      # @param [Object] value
      #
      # @return [Question]
      #
      # @api public
      def validate(value = nil, message = nil, &block)
        messages[:valid?] = message if message
        @validation = (value || block)
      end

      # Prepopulate input with custom content
      #
      # @api public
      def value(val)
        return @value if val.nil?

        @value = val
      end

      # Check if custom value is present
      #
      # @api private
      def value?
        @value != UndefinedSetting
      end

      def validation?
        @validation != UndefinedSetting
      end

      # Modify string according to the rule given.
      #
      # @param [Symbol] rule
      #
      # @api public
      def modify(*rules)
        @modifier = rules
      end

      # Turn terminal echo on or off. This is used to secure the display so
      # that the entered characters are not echoed back to the screen.
      #
      # @api public
      def echo(value = nil)
        return @echo if value.nil?

        @echo = value
      end
      alias echo? echo

      # Turn raw mode on or off. This enables character-based input.
      #
      # @api public
      def raw(value = nil)
        return @raw if value.nil?

        @raw = value
      end
      alias raw? raw

      # Set expected range of values
      #
      # @param [String] value
      #
      # @api public
      def in(value = (not_set = true), message = nil)
        messages[:range?] = message if message
        if in? && !@in.is_a?(Range)
          @in = Converters.convert(:range, @in)
        end
        return @in if not_set

        @in = Converters.convert(:range, value)
      end

      # Check if range is set
      #
      # @return [Boolean]
      #
      # @api public
      def in?
        @in != UndefinedSetting
      end

      # Set quiet mode.
      #
      # @api public
      def quiet(value)
        @quiet = value
      end

      # @api public
      def to_s
        message.to_s
      end

      # String representation of this question
      # @api public
      def inspect
        "#<#{self.class.name} @message=#{message}, @input=#{@input}>"
      end
    end # Question
  end # Prompt
end # TTY
