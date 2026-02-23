# frozen_string_literal: true

require 'logger'

module Weird
  # Things for logs/status messages
  # Use of status:
  #   all: site started ended, major sections entered. Also to STDOUT.
  #   light: how much work was done, minor sections entered. Also to STDOUT.
  #   verbose: almost a full stack trace. To logfile.

  # ARGY: This is somewhat rubbish
  # CURRENT Example use cases:
  # status('Always gunna log this', interesting_variable)
  # status('Heading', section_identifier_variable, true, logging_level)
  # status('Detail', interesting_variable,false,logging_level)
  # Noting that there is currently no mechanism in status for reducing indent
  # eg: the "true/false" needs to be more like +1, 0, -1, or keywords to that effect

  def status(var_name, value, is_section = false, level = :verbose)
    return unless log?(level)

    if is_section
      puts "\n>>> #{var_name}"
      $status_indent = 1
    else
      indent = '  ' * $status_indent
      puts "#{indent}> #{var_name}: #{value.inspect}"
    end
  end

  # Helper to determine if a message should be logged based on the current LOG_LEVEL
  # Probably rubbish
  def log?(level)
    case LOG_LEVEL
    when :none
      false
    when :light
      %i[light all].include?(level)
    when :verbose
      true
    end
  end

  class Logging
    attr_reader :log_level

    def initialize(dest: $stderr, level: Logger::Severity::DEBUG)
      @logger = Logger.new(dest, level: level)
      @indent = 0
      @log_level = Logger::Severity.coerce(level)
      @enabled = true
    rescue ArgumentError
      @enabled = false
    end

    def status(var_name, value, level: Logger::Severity::DEBUG)
      return unless @enabled

      indent = ' ' * @indent
      @logger.log(level, "#{indent}> #{var_name}: #{value.inspect}")
    end

    def section(title, level: Logger::Severity::DEBUG)
      return unless @enabled

      @logger.log(level, "\n>>> #{title}")
      @indent = 1
    end

    def end_section(title, level: Logger::Severity::DEBUG)
      return unless @enabled

      @logger.log(level, "<<< #{title}")
      @indent = 0
    end
  end
end
