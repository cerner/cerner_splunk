require 'syslog'
require 'logger'
require 'syslog-formatter'

class Logger::Syslog
  include Logger::Severity

  # The version of Logger::Syslog you are using.
  VERSION = '1.6.8'

  # From 'man syslog.h':
  # LOG_EMERG   A panic condition was reported to all processes.
  # LOG_ALERT   A condition that should be corrected immediately.
  # LOG_CRIT    A critical condition.
  # LOG_ERR     An error message.
  # LOG_WARNING A warning message.
  # LOG_NOTICE  A condition requiring special handling.
  # LOG_INFO    A general information message.
  # LOG_DEBUG   A message useful for debugging programs.

  # From logger rdoc:
  # FATAL:  an unhandleable error that results in a program crash
  # ERROR:  a handleable error condition
  # WARN:   a warning
  # INFO:   generic (useful) information about system operation
  # DEBUG:  low-level information for developers

  # Maps Logger warning types to syslog(3) warning types.
  LOGGER_MAP = {
    :unknown => :alert,
    :fatal   => :crit,
    :error   => :err,
    :warn    => :warning,
    :info    => :info,
    :debug   => :debug
  }

  # Maps Logger log levels to their values so we can silence.
  LOGGER_LEVEL_MAP = {}

  LOGGER_MAP.each_key do |key|
    LOGGER_LEVEL_MAP[key] = Logger.const_get key.to_s.upcase
  end

  # Maps Logger log level values to syslog log levels.
  LEVEL_LOGGER_MAP = {}

  LOGGER_LEVEL_MAP.invert.each do |level, severity|
    LEVEL_LOGGER_MAP[level] = LOGGER_MAP[severity]
  end

  # Builds a methods for level +meth+.
  for severity in Logger::Severity.constants
    class_eval <<-EOT, __FILE__, __LINE__
      def #{severity.downcase}(message = nil, progname = nil, &block)  # def debug(message = nil, progname = nil, &block)
        add(#{severity}, message, progname, &block)                    #   add(DEBUG, message, progname, &block)
      end                                                              # end
                                                                       #
      def #{severity.downcase}?                                        # def debug?
        @level <= #{severity}                                          #   @level <= DEBUG
      end                                                              # end
    EOT
  end

  # Log level for Logger compatibility.
  attr_accessor :level

  # Logging program name.
  attr_accessor :progname

  # Logging date-time format (string passed to +strftime+).
  def datetime_format=(datetime_format)
    @default_formatter.datetime_format = datetime_format
  end

  def datetime_format
    @default_formatter.datetime_format
  end

  # Logging formatter.  formatter#call is invoked with 4 arguments; severity,
  # time, progname and msg for each log.  Bear in mind that time is a Time and
  # msg is an Object that user passed and it could not be a String.  It is
  # expected to return a logdev#write-able Object.  Default formatter is used
  # when no formatter is set.
  attr_accessor :formatter

  alias sev_threshold level
  alias sev_threshold= level=

  # Fills in variables for Logger compatibility.  If this is the first
  # instance of Logger::Syslog, +program_name+ may be set to change the logged
  # program name and +facility+ may be set to specify a custom facility
  # with your syslog daemon.
  #
  # Due to the way syslog works, only one program name may be chosen.
  def initialize(program_name = 'rails', facility = Syslog::LOG_USER, logopts=nil)
    @default_formatter = Logger::SyslogFormatter.new
    @formatter         = nil
    @progname          = nil
    @level             = Logger::DEBUG

    return if defined? SYSLOG
    self.class.const_set :SYSLOG, Syslog.open(program_name, logopts, facility)
  end

  # Almost duplicates Logger#add.  +progname+ is ignored.
  def add(severity, message = nil, progname = nil, &block)
    severity ||= Logger::UNKNOWN
    if severity < @level
      return true
    end
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end
    SYSLOG.send(LEVEL_LOGGER_MAP[severity], format_message(format_severity(severity), Time.now, progname, clean(message)))
    true
  end

  # Allows messages of a particular log level to be ignored temporarily.
  def silence(temporary_level = Logger::ERROR)
    old_logger_level = @level
    @level = temporary_level
    yield
  ensure
    @level = old_logger_level
  end

  # In Logger, this dumps the raw message; the closest equivalent
  # would be Logger::UNKNOWN
  def <<(message)
    add(Logger::UNKNOWN, message)
  end

  private

    # Severity label for logging. (max 5 char)
    SEV_LABEL = %w(DEBUG INFO WARN ERROR FATAL ANY)

    def format_severity(severity)
      SEV_LABEL[severity] || 'ANY'
    end

    def format_message(severity, datetime, progname, msg)
      (@formatter || @default_formatter).call(severity, datetime, progname, msg)
    end

    # Clean up messages so they're nice and pretty.
    def clean(message)
      message = message.to_s.dup
      message.strip!
      message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)
      message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
      return message
    end

end