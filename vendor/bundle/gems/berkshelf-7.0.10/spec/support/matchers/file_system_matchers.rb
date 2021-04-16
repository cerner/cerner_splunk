# Taken from (https://github.com/carlhuda/beard)
# Permission granted by Yehuda Katz (Jan 4th, 2012)
module Berkshelf
  module RSpec
    module FileSystemMatchers
      class FileMatcher
        def initialize(name, &block)
          @contents = []
          @negative_contents = []
          @name = name

          if block_given?
            instance_eval(&block)
          end
        end

        def contains(text)
          @contents << text
        end

        def does_not_contain(text)
          @negative_contents << text
        end

        def matches?(root)
          path = Pathname.glob(root.join(@name)).first
          unless path.exist?
            throw :failure, root.join(@name)
          end

          contents = File.read(path)

          @contents.each do |string|
            unless contents.include?(string)
              throw :failure, [root.join(@name), string, contents]
            end
          end

          @negative_contents.each do |string|
            if contents.include?(string)
              throw :failure, [:not, root.join(@name), string, contents]
            end
          end
        end
      end

      class DirectoryMatcher
        attr_reader :tree

        def initialize(root = nil, &block)
          @tree = {}
          @negative_tree = []
          @root = root
          instance_eval(&block) if block_given?
        end

        def directory(name, &block)
          @tree[name] = block_given? && DirectoryMatcher.new(location(name), &block)
        end

        def file(name, &block)
          @tree[name] = FileMatcher.new(location(name), &block)
        end

        def no_file(name)
          @negative_tree << name
        end

        def location(name)
          [@root, name].compact.join("/")
        end

        def matches?(root)
          @tree.each do |file, value|
            unless value
              unless root.join(location(file)).exist?
                throw :failure, "#{root}/#{location(file)}"
              end
            else
              value.matches?(root)
            end
          end

          @negative_tree.each do |file|
            if root.join(location(file)).exist?
              throw :failure, [:not, "unexpected #{root}/#{location(file)}"]
            end
          end

          nil
        end
      end

      class RootMatcher < DirectoryMatcher
        def failure_message
          if @failure.is_a?(Array) && @failure[0] == :not
            if @failure[2]
              "File #{@failure[1]} should not have contained \"#{@failure[2]}\""
            else
              "Structure should not have had #{@failure[1]}, but it did"
            end
          elsif @failure.is_a?(Array)
            "Structure should have #{@failure[0]} with #{@failure[1]}. It had:\n#{@failure[2]}"
          else
            "Structure should have #{@failure}, but it didn't"
          end
        end

        def failure_message_when_negated
          if @failure.is_a?(Array) && @failure[0] == :not
            "Structure had #{@failure}, but it shouldn't have"
          else
            "Structure had #{@failure}, but it shouldn't have"
          end
        end

        def description
          "have structure"
        end

        def matches?(root)
          @failure = catch :failure do
            super
          end

          !@failure
        end
      end

      def have_structure(&block)
        RootMatcher.new(&block)
      end
    end
  end
end
