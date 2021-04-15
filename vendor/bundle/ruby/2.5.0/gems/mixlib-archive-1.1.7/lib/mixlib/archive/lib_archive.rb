require "ffi-libarchive"

module Mixlib
  class Archive
    class LibArchive
      attr_reader :options
      attr_reader :archive

      def initialize(archive, options = {})
        @archive = archive
        @options = options
      end

      # Extracts the archive to the given +destination+
      #
      # === Parameters
      # perms<Boolean>:: should the extracter use permissions from the archive.
      # ignore[Array]:: an array of matches of file paths to ignore
      def extract(destination, perms: true, ignore: [])
        ignore_re = Regexp.union(ignore)
        flags = perms ? ::Archive::EXTRACT_PERM : nil
        FileUtils.mkdir_p(destination)

        reader = ::Archive::Reader.open_filename(@archive)

        reader.each_entry do |entry|
          if entry.pathname =~ ignore_re
            Mixlib::Archive::Log.warn "ignoring entry #{entry.pathname}"
            next
          end

          reader.extract(entry, flags.to_i, destination: destination.to_s)
        end
        reader.close
      end

      # Creates an archive with the given set of +files+
      #
      # === Parameters
      # gzip<Boolean>:: should the archive be gzipped?
      def create(files, gzip: false)
        compression = gzip ? ::Archive::COMPRESSION_GZIP : ::Archive::COMPRESSION_NONE
        # "PAX restricted" will use PAX extensions when it has to, but will otherwise
        # use ustar for maximum compatibility
        format = ::Archive::FORMAT_TAR_PAX_RESTRICTED

        ::Archive.write_open_filename(archive, compression, format) do |tar|
          files.each do |fn|
            tar.new_entry do |entry|
              content = nil
              entry.pathname = fn
              stat = File.lstat(fn)
              if File.file?(fn)
                content = File.read(fn, mode: "rb")
                entry.size = content.bytesize
              end
              entry.mode = stat.mode
              entry.filetype = resolve_type(stat.ftype)
              entry.atime = stat.atime
              entry.mtime = stat.mtime
              entry.symlink = File.readlink(fn) if File.symlink?(fn)
              tar.write_header(entry)

              tar.write_data(content) unless content.nil?
            end
          end
        end
      end

      def resolve_type(type)
        case type
        when "characterSpecial"
          ::Archive::Entry::CHARACTER_SPECIAL
        when "blockSpecial"
          ::Archive::Entry::BLOCK_SPECIAL
        when "link"
          ::Archive::Entry::SYMBOLIC_LINK
        else
          ::Archive::Entry.const_get(type.upcase)
        end
      end
    end
  end
end
