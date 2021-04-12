module CookbookOmnifetch

  class OmnifetchError < StandardError
    class << self
      # @param [Integer] code
      def status_code(code)
        define_method(:status_code) { code }
        define_singleton_method(:status_code) { code }
      end
    end

    alias_method :message, :to_s
  end

  class AbstractFunction < OmnifetchError; end

  class GitError < OmnifetchError
    status_code(400)
  end

  class GitNotInstalled < GitError
    def initialize
      super "You need to install Git before you can download " \
        "cookbooks from git repositories. For more information, please " \
        "see the Git docs: http://git-scm.org."
    end
  end

  class GitCommandError < GitError
    def initialize(command, path, stderr = nil)
      out =  "Git error: command `git #{command}` failed. If this error "
      out << "persists, try removing the cache directory at '#{path}'."

      if stderr
        out << "Output from the command:\n\n"
        out << stderr
      end

      super(out)
    end
  end

  # NOTE: This is the only error class copied from berks that is also used
  # elsewhere in berks, in 'berkshelf/init_generator'

  class NotACookbook < OmnifetchError
    status_code(141)

    # @param [String] path
    #   the path to the thing that is not a cookbook
    def initialize(path)
      @path = File.expand_path(path) rescue path
      super(to_s)
    end

    def to_s
      "The resource at '#{@path}' does not appear to be a valid cookbook. " \
      "Does it have a metadata.rb?"
    end
  end

  class CookbookValidationFailure < OmnifetchError
    status_code(124)

    # @param [Location] location
    #   the location (or any subclass) raising this validation error
    # @param [CachedCookbook] cached_cookbook
    #   the cached_cookbook that does not satisfy the constraint
    def initialize(dependency, cached_cookbook)
      @dependency      = dependency
      @cached_cookbook = cached_cookbook
      super(to_s)
    end

    def to_s
      "The cookbook downloaded for #{@dependency} did not satisfy the constraint."
    end
  end

  class MismatchedCookbookName < OmnifetchError
    status_code(114)

    # @param [Dependency] dependency
    #   the dependency with the expected name
    # @param [CachedCookbook] cached_cookbook
    #   the cached_cookbook with the mismatched name
    def initialize(dependency, cached_cookbook)
      @dependency      = dependency
      @cached_cookbook = cached_cookbook
      super(to_s)
    end

    def to_s
      out =  "In your Berksfile, you have:\n"
      out << "\n"
      out << "  cookbook '#{@dependency.name}'\n"
      out << "\n"
      out << "But that cookbook is actually named '#{@cached_cookbook.cookbook_name}'\n"
      out << "\n"
      out << "This can cause potentially unwanted side-effects in the future.\n"
      out << "\n"
      out << "NOTE: If you do not explicitly set the 'name' attribute in the "
      out << "metadata, the name of the directory will be used instead. This "
      out << "is often a cause of confusion for dependency solving.\n"
      out
    end
  end

end
