require "ffi" unless defined?(FFI)

module Archive
  module C
    def self.attach_function_maybe(*args)
      attach_function(*args)
    rescue FFI::NotFoundError # rubocop:disable Lint/HandleExceptions
    end

    extend FFI::Library
    ffi_lib %w{libarchive.so.13 libarchive.13 libarchive-13 libarchive.so libarchive archive}

    attach_function :archive_version_number, [], :int
    attach_function :archive_version_string, [], :string
    attach_function :archive_error_string, [:pointer], :string
    attach_function :archive_errno, [:pointer], :int

    attach_function :archive_read_new, [], :pointer
    attach_function :archive_read_open_filename, %i{pointer string size_t}, :int
    attach_function :archive_read_open_memory, %i{pointer pointer size_t}, :int
    attach_function :archive_read_open1, [:pointer], :int
    attach_function :archive_read_support_compression_program, %i{pointer string}, :int
    attach_function :archive_read_support_compression_all, [:pointer], :int

    callback :archive_read_callback, %i{pointer pointer pointer}, :int
    callback :archive_skip_callback, %i{pointer pointer int64}, :int
    callback :archive_seek_callback, %i{pointer pointer int64 int}, :int
    attach_function :archive_read_set_read_callback, %i{pointer archive_read_callback}, :int
    attach_function :archive_read_set_callback_data, %i{pointer pointer}, :int
    attach_function :archive_read_set_skip_callback, %i{pointer archive_skip_callback}, :int
    attach_function :archive_read_set_seek_callback, %i{pointer archive_seek_callback}, :int

    attach_function_maybe :archive_read_set_format, %i{pointer int}, :int
    attach_function_maybe :archive_read_append_filter, %i{pointer int}, :int
    attach_function_maybe :archive_read_append_filter_program, %i{pointer pointer}, :int
    attach_function_maybe :archive_read_append_filter_program_signature, %i{pointer string pointer size_t}, :int

    attach_function_maybe :archive_read_support_filter_all, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_bzip2, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_compress, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_gzip, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_grzip, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_lrzip, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_lz4, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_lzip, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_lzma, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_lzop, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_none, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_program, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_program_signature, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_rpm, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_uu, [:pointer], :int
    attach_function_maybe :archive_read_support_filter_xz, [:pointer], :int

    attach_function_maybe :archive_read_support_format_all, [:pointer], :int
    attach_function_maybe :archive_read_support_format_7zip, [:pointer], :int
    attach_function_maybe :archive_read_support_format_ar, [:pointer], :int
    attach_function_maybe :archive_read_support_format_by_code, [:pointer], :int
    attach_function_maybe :archive_read_support_format_cab, [:pointer], :int
    attach_function_maybe :archive_read_support_format_cpio, [:pointer], :int
    attach_function_maybe :archive_read_support_format_empty, [:pointer], :int
    attach_function_maybe :archive_read_support_format_gnutar, [:pointer], :int
    attach_function_maybe :archive_read_support_format_iso9660, [:pointer], :int
    attach_function_maybe :archive_read_support_format_lha, [:pointer], :int
    attach_function_maybe :archive_read_support_format_mtree, [:pointer], :int
    attach_function_maybe :archive_read_support_format_rar, [:pointer], :int
    attach_function_maybe :archive_read_support_format_raw, [:pointer], :int
    attach_function_maybe :archive_read_support_format_tar, [:pointer], :int
    attach_function_maybe :archive_read_support_format_warc, [:pointer], :int
    attach_function_maybe :archive_read_support_format_xar, [:pointer], :int
    attach_function_maybe :archive_read_support_format_zip, [:pointer], :int
    attach_function_maybe :archive_read_support_format_zip_streamable, [:pointer], :int
    attach_function_maybe :archive_read_support_format_zip_seekable, [:pointer], :int

    attach_function :archive_read_finish, [:pointer], :int
    attach_function :archive_read_extract, %i{pointer pointer int}, :int
    attach_function :archive_read_header_position, [:pointer], :int
    attach_function :archive_read_next_header, %i{pointer pointer}, :int
    attach_function :archive_read_data, %i{pointer pointer size_t}, :size_t
    attach_function :archive_read_data_into_fd, %i{pointer int}, :int

    attach_function :archive_write_new, [], :pointer
    attach_function :archive_write_open_filename, %i{pointer string}, :int
    callback :archive_open_callback, %i{pointer pointer}, :int
    callback :archive_write_callback, %i{pointer pointer pointer size_t}, :int
    callback :archive_close_callback, %i{pointer pointer}, :int
    attach_function :archive_write_open, %i{pointer pointer pointer archive_write_callback pointer}, :int
    attach_function :archive_write_set_compression_none, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_gzip, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_bzip2, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_deflate, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_compress, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_lzma, [:pointer], :int
    attach_function_maybe :archive_write_set_compression_xz, [:pointer], :int
    attach_function :archive_write_set_compression_program, %i{pointer string}, :int

    def self.archive_write_set_compression(archive, compression)
      case compression
      when String
        archive_write_set_compression_program archive, compression
      when COMPRESSION_BZIP2
        archive_write_set_compression_bzip2 archive
      when COMPRESSION_GZIP
        archive_write_set_compression_gzip archive
      when COMPRESSION_LZMA
        archive_write_set_compression_lzma archive
      when COMPRESSION_XZ
        archive_write_set_compression_xz archive
      when COMPRESSION_COMPRESS
        archive_write_set_compression_compress archive
      when COMPRESSION_NONE
        archive_write_set_compression_none archive
      else
        raise "Unknown compression type: #{compression}"
      end
    end

    attach_function :archive_write_set_format, %i{pointer int}, :int
    attach_function :archive_write_data, %i{pointer pointer size_t}, :ssize_t
    attach_function :archive_write_header, %i{pointer pointer}, :int
    attach_function :archive_write_finish, [:pointer], :void
    attach_function :archive_write_get_bytes_in_last_block, [:pointer], :int
    attach_function :archive_write_set_bytes_in_last_block, %i{pointer int}, :int

    attach_function :archive_entry_new, [], :pointer
    attach_function :archive_entry_clone, [:pointer], :pointer
    attach_function :archive_entry_free, [:pointer], :void
    attach_function :archive_entry_atime, [:pointer], :time_t
    attach_function :archive_entry_atime_nsec, %i{pointer time_t long}, :void
    attach_function_maybe :archive_entry_atime_is_set, [:pointer], :int
    attach_function :archive_entry_set_atime, %i{pointer time_t long}, :int
    attach_function_maybe :archive_entry_unset_atime, [:pointer], :int
    attach_function_maybe :archive_entry_birthtime, [:pointer], :time_t
    attach_function_maybe :archive_entry_birthtime_nsec, %i{pointer time_t long}, :void
    attach_function_maybe :archive_entry_birthtime_is_set, [:pointer], :int
    attach_function_maybe :archive_entry_set_birthtime, %i{pointer time_t long}, :int
    attach_function_maybe :archive_entry_unset_birthtime, [:pointer], :int
    attach_function :archive_entry_ctime, [:pointer], :time_t
    attach_function :archive_entry_ctime_nsec, %i{pointer time_t long}, :void
    attach_function_maybe :archive_entry_ctime_is_set, [:pointer], :int
    attach_function :archive_entry_set_ctime, %i{pointer time_t long}, :int
    attach_function_maybe :archive_entry_unset_ctime, [:pointer], :int
    attach_function :archive_entry_mtime, [:pointer], :time_t
    attach_function :archive_entry_mtime_nsec, %i{pointer time_t long}, :void
    attach_function_maybe :archive_entry_mtime_is_set, [:pointer], :int
    attach_function :archive_entry_set_mtime, %i{pointer time_t long}, :int
    attach_function_maybe :archive_entry_unset_mtime, [:pointer], :int
    attach_function :archive_entry_dev, [:pointer], :dev_t
    attach_function :archive_entry_set_dev, %i{pointer dev_t}, :void
    attach_function :archive_entry_devmajor, [:pointer], :dev_t
    attach_function :archive_entry_set_devmajor, %i{pointer dev_t}, :void
    attach_function :archive_entry_devminor, [:pointer], :dev_t
    attach_function :archive_entry_set_devminor, %i{pointer dev_t}, :void
    attach_function :archive_entry_filetype, [:pointer], :mode_t
    attach_function :archive_entry_set_filetype, %i{pointer mode_t}, :void
    attach_function :archive_entry_fflags, %i{pointer pointer pointer}, :void
    attach_function :archive_entry_set_fflags, %i{pointer ulong ulong}, :void
    attach_function :archive_entry_fflags_text, [:pointer], :string
    attach_function :archive_entry_gid, [:pointer], :uint
    attach_function :archive_entry_set_gid, %i{pointer uint}, :void
    attach_function :archive_entry_gname, [:pointer], :string
    attach_function :archive_entry_set_gname, %i{pointer string}, :void
    attach_function :archive_entry_hardlink, [:pointer], :string
    attach_function :archive_entry_set_hardlink, %i{pointer string}, :void
    attach_function :archive_entry_set_link, %i{pointer string}, :void
    attach_function :archive_entry_ino, [:pointer], :ino_t
    attach_function :archive_entry_set_ino, %i{pointer ino_t}, :void
    attach_function :archive_entry_mode, [:pointer], :mode_t
    attach_function :archive_entry_set_mode, %i{pointer mode_t}, :void
    attach_function :archive_entry_set_perm, %i{pointer mode_t}, :void
    attach_function :archive_entry_nlink, [:pointer], :uint
    attach_function :archive_entry_set_nlink, %i{pointer uint}, :void
    attach_function :archive_entry_pathname, [:pointer], :string
    attach_function :archive_entry_set_pathname, %i{pointer string}, :void
    attach_function :archive_entry_rdev, [:pointer], :dev_t
    attach_function :archive_entry_set_rdev, %i{pointer dev_t}, :void
    attach_function :archive_entry_rdevmajor, [:pointer], :dev_t
    attach_function :archive_entry_set_rdevmajor, %i{pointer dev_t}, :void
    attach_function :archive_entry_rdevminor, [:pointer], :dev_t
    attach_function :archive_entry_set_rdevminor, %i{pointer dev_t}, :void
    attach_function :archive_entry_size, [:pointer], :int64_t
    attach_function :archive_entry_set_size, %i{pointer int64_t}, :void
    attach_function_maybe :archive_entry_unset_size, [:pointer], :void
    attach_function_maybe :archive_entry_size_is_set, [:pointer], :int
    attach_function :archive_entry_sourcepath, [:pointer], :string
    attach_function :archive_entry_strmode, [:pointer], :string
    attach_function :archive_entry_symlink, [:pointer], :string
    attach_function :archive_entry_set_symlink, %i{pointer string}, :void
    attach_function :archive_entry_uid, [:pointer], :uint
    attach_function :archive_entry_set_uid, %i{pointer uint}, :void
    attach_function :archive_entry_uname, [:pointer], :string
    attach_function :archive_entry_set_uname, %i{pointer string}, :void
    attach_function :archive_entry_copy_stat, %i{pointer pointer}, :void
    attach_function :archive_entry_copy_fflags_text, %i{pointer string}, :string
    attach_function :archive_entry_copy_gname, %i{pointer string}, :string
    attach_function :archive_entry_copy_uname, %i{pointer string}, :string
    attach_function :archive_entry_copy_hardlink, %i{pointer string}, :string
    attach_function :archive_entry_copy_link, %i{pointer string}, :string
    attach_function :archive_entry_copy_symlink, %i{pointer string}, :string
    attach_function :archive_entry_copy_sourcepath, %i{pointer string}, :string
    attach_function :archive_entry_copy_pathname, %i{pointer string}, :string
    attach_function :archive_entry_xattr_clear, [:pointer], :void
    attach_function :archive_entry_xattr_add_entry, %i{pointer string pointer size_t}, :void
    attach_function :archive_entry_xattr_count, [:pointer], :int
    attach_function :archive_entry_xattr_reset, [:pointer], :int
    attach_function :archive_entry_xattr_next, %i{pointer pointer pointer pointer}, :int

    EOF    = 1
    OK     = 0
    RETRY  = -10
    WARN   = -20
    FAILED = -25
    FATAL  = -30

    DATA_BUFFER_SIZE = 2**16
  end

  COMPRESSION_NONE     = 0
  COMPRESSION_GZIP     = 1
  COMPRESSION_BZIP2    = 2
  COMPRESSION_COMPRESS = 3
  COMPRESSION_PROGRAM  = 4
  COMPRESSION_LZMA     = 5
  COMPRESSION_XZ       = 6
  COMPRESSION_UU       = 7
  COMPRESSION_RPM      = 8
  COMPRESSION_LZIP     = 9
  COMPRESSION_LRZIP    = 10
  COMPRESSION_LZOP     = 11
  COMPRESSION_GRZIP    = 12
  COMPRESSION_LZ4      = 13

  FORMAT_BASE_MASK           = 0xff0000
  FORMAT_CPIO                = 0x10000
  FORMAT_CPIO_POSIX          = (FORMAT_CPIO | 1)
  FORMAT_CPIO_BIN_LE         = (FORMAT_CPIO | 2)
  FORMAT_CPIO_BIN_BE         = (FORMAT_CPIO | 3)
  FORMAT_CPIO_SVR4_NOCRC     = (FORMAT_CPIO | 4)
  FORMAT_CPIO_SVR4_CRC       = (FORMAT_CPIO | 5)
  FORMAT_SHAR                = 0x20000
  FORMAT_SHAR_BASE           = (FORMAT_SHAR | 1)
  FORMAT_SHAR_DUMP           = (FORMAT_SHAR | 2)
  FORMAT_TAR                 = 0x30000
  FORMAT_TAR_USTAR           = (FORMAT_TAR | 1)
  FORMAT_TAR_PAX_INTERCHANGE = (FORMAT_TAR | 2)
  FORMAT_TAR_PAX_RESTRICTED  = (FORMAT_TAR | 3)
  FORMAT_TAR_GNUTAR          = (FORMAT_TAR | 4)
  FORMAT_ISO9660             = 0x40000
  FORMAT_ISO9660_ROCKRIDGE   = (FORMAT_ISO9660 | 1)
  FORMAT_ZIP                 = 0x50000
  FORMAT_EMPTY               = 0x60000
  FORMAT_AR                  = 0x70000
  FORMAT_AR_GNU              = (FORMAT_AR | 1)
  FORMAT_AR_BSD              = (FORMAT_AR | 2)
  FORMAT_MTREE               = 0x80000
  FORMAT_RAW                 = 0x90000
  FORMAT_XAR                 = 0xA0000
  FORMAT_LHA                 = 0xB0000
  FORMAT_CAB                 = 0xC0000
  FORMAT_RAR                 = 0xD0000
  FORMAT_7ZIP                = 0xE0000
  FORMAT_WARC                = 0xF0000

  EXTRACT_OWNER              = 0x0001
  EXTRACT_PERM               = 0x0002
  EXTRACT_TIME               = 0x0004
  EXTRACT_NO_OVERWRITE       = 0x0008
  EXTRACT_UNLINK             = 0x0010
  EXTRACT_ACL                = 0x0020
  EXTRACT_FFLAGS             = 0x0040
  EXTRACT_XATTR              = 0x0080
  EXTRACT_SECURE_SYMLINKS    = 0x0100
  EXTRACT_SECURE_NODOTDOT    = 0x0200
  EXTRACT_NO_AUTODIR         = 0x0400
  EXTRACT_NO_OVERWRITE_NEWER = 0x0800
  EXTRACT_SPARSE             = 0x1000
  EXTRACT_MAC_METADATA       = 0x2000
  EXTRACT_NO_HFS_COMPRESSION = 0x4000
  EXTRACT_HFS_COMPRESSION_FORCED = 0x8000
  EXTRACT_SECURE_NOABSOLUTEPATHS = 0x10000
  EXTRACT_CLEAR_NOCHANGE_FFLAGS = 0x20000

  def self.read_open_filename(file_name, command = nil, &block)
    Reader.open_filename file_name, command, &block
  end

  def self.read_open_memory(string, command = nil, &block)
    Reader.open_memory string, command, &block
  end

  def self.read_open_stream(reader, &block)
    Reader.open_stream reader, &block
  end

  def self.write_open_filename(file_name, compression, format, &block)
    Writer.open_filename file_name, compression, format, &block
  end

  def self.write_open_memory(string, compression, format, &block)
    Writer.open_memory string, compression, format, &block
  end

  def self.version_number
    C.archive_version_number
  end

  def self.version_string
    C.archive_version_string
  end

  class Error < StandardError
    def initialize(archive)
      if archive.is_a? String
        super archive
      else
        super C.archive_error_string(archive).to_s
      end
    end
  end

  class BaseArchive
    def initialize(alloc, free)
      @archive = nil
      @archive_free = nil
      @archive = alloc.call
      @archive_free = [nil]
      raise Error, @archive unless @archive

      @archive_free[0] = free
      ObjectSpace.define_finalizer(self, BaseArchive.finalizer(@archive, @archive_free))
    end

    def self.finalizer(archive, archive_free)
      proc do |*_args|
        archive_free[0].call(archive) if archive_free[0]
      end
    end

    def close
      # TODO: do we need synchronization here?
      if @archive
        # TODO: Error check?
        @archive_free[0].call(@archive)
      end
    ensure
      @archive = nil
      @archive_free[0] = nil
      @data = nil
    end

    def archive
      raise Error, "No archive open" unless @archive

      @archive
    end
    protected :archive

    def error_string
      C.archive_error_string(@archive)
    end

    def errno
      C.archive_errno(@archive)
    end
  end
end
