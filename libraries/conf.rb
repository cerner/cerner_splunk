# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: conf.rb

module CernerSplunk
  # Utilities for working with splunk configuration files
  module Conf
    STANZA_START ||= /^\s*\[(?<stanza_name>[^\]]+)\].*$/
    COMMENT_LINE ||= /^\s*#.*$/
    KEY_VALUE_PAIR ||= /^(?<key>[^=]+)=(?<value>.*)$/

    def self.parse_string(conf)
      return {} if conf.nil?
      parse StringIO.open(conf, 'r:UTF-8')
    end

    def self.parse(io)
      start = {}
      hash = { 'default' => start }
      current = start

      io.each_line do |line|
        case line
        when STANZA_START
          start = {}
          current = start
          hash[Regexp.last_match(:stanza_name).strip] = start
        when COMMENT_LINE
          # ignore comment lines
        when KEY_VALUE_PAIR
          current[Regexp.last_match(:key).strip] = Regexp.last_match(:value).strip
        end
      end

      hash.delete('default') if hash['default'].empty?
      hash
    end

    # Class for reading an existing configuration file from disk
    class Reader
      def initialize(filename)
        @filename = filename
      end

      def read
        return {} unless File.exist?(@filename)
        file = File.open(@filename, 'r:UTF-8')
        CernerSplunk::Conf.parse file
      ensure
        file.close if file
      end
    end
  end
end
