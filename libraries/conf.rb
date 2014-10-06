# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: conf.rb

module CernerSplunk
  module Conf
    # Class for reading an existing configuration file from disk
    class Reader
      def initialize(filename)
        @filename = filename
      end

      def read
        return {} unless File.exist?(@filename)

        start = {}
        hash = { 'default' => start }
        current = start

        File.open(@filename, 'r:UTF-8').each_line do |line|
          case line
          when /^\s*\[([^\]]+)\].*$/
            start = {}
            current = start
            hash[Regexp.last_match[1].strip] = start
          when /^\s*#.*$/
            # ignore comment lines
          when /^([^=]+)=(.*)$/
            current[Regexp.last_match[1].strip] = Regexp.last_match[2].strip
          end
        end

        hash.keep_if do |_, value|
          !value.empty?
        end
      end
    end
  end
end
