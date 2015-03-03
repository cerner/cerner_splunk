# coding: UTF-8
#
# Cookbook Name:: cerner_splunk
# File Name:: tarball.rb
#
# Methods for working with data from a tarball.

require 'rubygems/package'
require 'zlib'
require 'fileutils'

module CernerSplunk
  # Utility class to encapsulate operations on tar.gz files
  # Mad Props to http://stackoverflow.com/a/19139114/504685
  class TarBall
    def initialize(file_name, options = {})
      @data = []
      @clean_proc = Remover.new(@data)
      ObjectSpace.define_finalizer(self, @clean_proc)
      @file_name = @data[0] = file_name
      @reader = @data[1] =  Gem::Package::TarReader.new(Zlib::GzipReader.open @file_name)
      @prefix = options[:prefix]
      @options = options
    end

    attr_reader :prefix

    def get_file(name)
      data = []
      target_path = @prefix.nil? ? name : "#{@prefix}/#{name}"
      iterate file: proc { |path, entry| data << entry.read if path == target_path }, other: proc {}
      fail "Multiple entries for #{target_path} found in #{@file_name}" if data.size > 1
      data.first
    end

    def extract(extract_dir)
      file_handler = proc do |path, entry|
        target = "#{extract_dir}/#{path}"
        make_dirs extract_dir, path
        File.open(target, 'wb') { |f| f.print entry.read }
        FileUtils.chmod entry.header.mode, target
        FileUtils.chown @options[:user], @options[:group], target
      end

      dir_handler = proc do |path, entry|
        target = "#{extract_dir}/#{path}"
        make_dirs extract_dir, path, true
        FileUtils.chmod entry.header.mode, target
      end

      symlink_handler = proc do |path, entry, other = {}|
        target = "#{extract_dir}/#{path}"
        make_dirs extract_dir, path
        File.unlink target if File.exist? target
        File.symlink other[:linkname], target
        FileUtils.chmod entry.header.mode, target
        FileUtils.chown @options[:user], @options[:group], target
      end

      iterate file: file_handler, directory: dir_handler, symlink: symlink_handler
    end

    # Count the number of (qualified) entries in the tarball where the return value
    # of the corresponding callback applied to each entry in the tarfile is truthy.
    # With no arguments, counts the number of qualified entries
    # If called with a block (only), the block is the callback to for every entry.
    # If called with a map, invoke the appropriate callback for each corresponding entry.
    # See iterate for details on how callbacks are invoked.
    def count(callbacks = {}, &other)
      callbacks = { other: other } if other && callbacks.empty?
      i = 0
      # Wrap each callback such that if it's truthy, we increment our counter.
      hsh = callbacks.each_with_object({}) { |(k, v), h| h[k] = proc { |*args| i += 1 if v.call(args) } }
      hsh[:other] = proc { i += 1 } if hsh.empty?
      hsh[:other] = proc {} unless hsh[:other]
      iterate hsh
      i
    end

    def num_files
      count file: proc { true }
    end

    def make_dirs(extract_dir, path, all = false)
      segments = path.split('/')
      segments = segments[0...-1] unless all
      segments.each_with_object(extract_dir.dup) do |segment, target|
        target << "/#{segment}"
        FileUtils.mkdir target unless File.directory? target
        FileUtils.chown @options[:user], @options[:group], target
      end
    end

    # Iterate over the entries of the tarfile, and invoke the corresponding callback with each entry.
    # We handle the LongFileName and LongSymLink entries as found (no callbacks, but they change values sent with other callbacks)
    # If a prefix is set, we skip any entry whose path does not start with the prefix
    # The callbacks is a hash of Symbol or String mapped to Proc
    # callbacks with keys of :file, :directory, or :symlink would be invoked for file, directory, or symlink entries
    # callbacks with string keys, would be invoked if the header typeflag matches (in the absense of :file, :directory, or :symlink callbacks)
    # callbacks with a key of :other would be invoked if no other callback is found
    # If no callback at all is found for the current item, then we fail.
    def iterate(callbacks = {}) # rubocop:disable PerceivedComplexity, CyclomaticComplexity
      @reader.rewind
      long_path = nil
      long_link = nil
      @reader.each do |entry|
        case entry.header.typeflag
        when 'L' # LongFileName
          long_path = entry.read.strip
        when 'K' # LongSymLink
          long_link = entry.read.strip
        else
          path = long_path && long_path.start_with?(entry.full_name) ? long_path : entry.full_name
          linkname = long_link && long_link.start_with?(entry.header.linkname) ? long_link : entry.header.linkname

          # Determine which callback to invoke based on the typeflag
          callback = callbacks[:file] if entry.header.typeflag == '0'
          callback ||= callbacks[:directory] if entry.header.typeflag == '5'
          callback ||= callbacks[:symlink] if entry.header.typeflag == '2'
          callback ||= callbacks[entry.header.typeflag]
          callback ||= callbacks[:other]

          if @prefix.nil? || path.start_with?("#{@prefix}/")
            fail "Unsupported typeflag #{entry.header.typeflag} for path #{path}" unless callback

            callback.call path, entry, linkname: linkname
          end

          long_path = nil
          long_link = nil
        end
      end
    end

    def close
      @reader.close
      @data[0] = @file_name = nil
      @data[1] = @reader = nil
      ObjectSpace.undefine_finalizer(self)
    end

    # :stopdoc:
    # This pattern came from the Tempfile class in Ruby.
    class Remover
      def initialize(data)
        @pid = $PID
        @data = data
      end

      def call(*)
        return if @pid != $PID
        _, reader = *@data
        reader.close if reader
      end
    end
  end
end
