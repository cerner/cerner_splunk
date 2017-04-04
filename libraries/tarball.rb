# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: tarball.rb
#
# Methods for working with data from a tarball.

require 'rubygems'
require 'rubygems/package'
require 'zlib'
require 'fileutils'

module CernerSplunk
  # Utility class to encapulsate operations done on a tarball (tar.gz / tgz / spl) file, and not have a native dependency.
  # The core to this method is the iterate method, which invokes a provided callback for each encoutered entry, based on the kind of entry
  # Mad Props to http://stackoverflow.com/a/19139114/504685
  class TarBall
    # Standard initialization method to read the given tarball.
    # Options that could be set:
    # :prefix -> If set, any entry that does not start with this directory, is skipped when iteratating over entries.
    # :user -> user who should own extracted files / created directories (nil if no-change)
    # :group -> group who should own extracted files / created directories (nil if no-change)
    def initialize(file_name, options = {})
      # These first three lines are black magic with the below class to ensure that the reader gets closed.
      @data = []
      @clean_proc = Remover.new(@data)
      ObjectSpace.define_finalizer(self, @clean_proc)
      # Setup the reader, and read the prefix option if present.
      @file_name = @data[0] = file_name
      @io = @data[1] = Zlib::GzipReader.open @file_name
      @reader = @data[2] = Gem::Package::TarReader.new @io

      @prefix = options[:prefix]
      @options = options
      # chown blows up on windows in unexpected ways
      # so give us a marker to know if we can chown
      @can_chown = !Gem.win_platform?
    end

    attr_reader :prefix

    # Get the contents of a normal file with the given name.
    # If a prefix is set, the name argument is only the portion after the prefix.
    def get_file(name)
      data = []
      target_path = @prefix.nil? ? name : "#{@prefix}/#{name}"
      iterate file: proc { |path, entry| data << entry.read if path == target_path }, other: proc {}
      fail "Multiple entries for #{target_path} found in #{@file_name}" if data.size > 1
      data.first
    end

    # Extracts the tar to the target directory
    # If prefix is set, only extracts those matching the prefix, otherwise extracts all files.
    def extract(extract_dir)
      file_handler = proc do |path, entry|
        target = "#{extract_dir}/#{path}"
        make_dirs extract_dir, path
        File.open(target, 'wb') { |f| f.print entry.read }
        FileUtils.chmod entry.header.mode, target
        FileUtils.chown @options[:user], @options[:group], target if @can_chown
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
        FileUtils.chown @options[:user], @options[:group], target if @can_chown
      end

      iterate file: file_handler, directory: dir_handler, symlink: symlink_handler
    end

    # Count the number of (qualified) entries in the tarball where the return value
    # of the corresponding callback applied to each entry in the tarfile is truthy.
    # With no arguments, counts the number of qualified entries
    # If called with a block (only), the block is the callback to for every entry.
    # If called with a map, invoke the appropriate callback for each entry.
    # This can be used to tell things such as how many files are contained in the tarball with our prefix
    def count(callbacks = {}, &other)
      callbacks = { other: other } if other && callbacks.empty?
      i = 0
      # Wrap each callback such that if it's truthy, we increment our counter.
      hsh = callbacks.each_with_object({}) { |(k, v), h| h[k] = proc { |*args| i += 1 if v.call(args) } }
      # Default, count all entries (matching prefix if applicable)
      hsh[:other] = proc { i += 1 } if hsh.empty?
      # For Counting, ensure that we do not blow up for any unspecified types of entries
      hsh[:other] = proc {} unless hsh[:other]
      iterate hsh
      i
    end

    def num_files
      count file: proc { true }
    end

    # As entries in the tarball may skip directories, or may have directory entries after their contents
    # as we extract files, we use this to create intermediate directories
    def make_dirs(extract_dir, path, all = false)
      segments = path.split('/')
      segments = segments[0...-1] unless all
      segments.each_with_object(extract_dir.dup) do |segment, target|
        target << "/#{segment}"
        FileUtils.mkdir target unless File.directory? target
        FileUtils.chown @options[:user], @options[:group], target if @can_chown
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
      @clean_proc.call
      @data[0] = @file_name = nil
      @data[1] = @io = nil
      @data[2] = @reader = nil
      ObjectSpace.undefine_finalizer(self)
    end

    # :stopdoc:
    # This pattern came from the Tempfile class in Ruby.
    # This is simply a guard object to ensure that we close the reader object.
    class Remover
      def initialize(data)
        @pid = $PID
        @data = data
      end

      def call(*)
        return if @pid != $PID
        @data.drop(1).reverse_each { |io| io.close if io }
      end
    end
  end
end
