require 'colored'

module CLIntegracon

  # A LazyString is constructed by a block, but only evaluated when needed
  class LazyString

    # @return  [Proc]
    #          the closure which will be used to build the string
    attr_reader :proc

    # Initialize a LazyString
    #
    # @param  [Block () -> (String)] block
    #         the block which returns a string, called by #to_s
    #
    def initialize(&block)
      @proc = block
    end

    # Calls the underlying proc to build the string. The result will be
    # memorized, so subsequent calls of this method will not cause that the
    # proc will be called again.
    #
    # @return [String]
    #
    def to_str
      @string ||= proc.call().to_s
    end

    alias :to_s :to_str

  end

  # A LazyStringProxy returns a LazyString for each call, which delegates the
  # call as soon as the result is needed to the underlying formatter.
  class LazyStringProxy

    # @return  [Formatter]
    #          the formatter used to build the string
    attr_reader :formatter

    # Initialize a LazyStringProxy, which returns for each call to an
    # underlying formatter a new LazyString, whose #to_s method will evaluate
    # to the result of the original call delegated to the formatter.
    #
    # @param  [Formatter] formatter
    #         the formatter
    #
    def initialize(formatter)
      @formatter = formatter
    end

    # Remember the call delegated to #formatter in a closure on an anonymous
    # object, defined as method :to_s.
    #
    # @return [#to_s]
    #
    def method_missing(method, *args, &block)
      return LazyString.new do
        @formatter.send(method, *args, &block)
      end
    end

    # Respond to all methods, which are beginning with `describe_` to
    # which the #formatter also responds.
    #
    # @return [Bool]
    #
    def respond_to?(method)
      if /^describe_/.match(method.to_s) && @formatter.respond_to?(method)
        true
      else
        super
      end
    end

  end

  class Formatter

    # @return  [FileTreeSpec]
    #          the spec
    attr_reader :spec

    # Initialize
    #
    # @param  [FileTreeSpec] spec
    #         the spec
    #
    def initialize(spec)
      super()
      @spec = spec
    end

    # Return a proxy, which returns formatted string, evaluated first
    # if #to_s is called on this instance.
    #
    # @return  [LazyStringProxy]
    #
    def lazy
      LazyStringProxy.new(self)
    end

    # Return a description text for an expectation that a file path
    # was expected to exist, but is missing.
    #
    # @param  [Pathname] file_path
    #         the file path which was expected to exist
    #
    # @return [String]
    #
    def describe_missing_file(file_path)
      description = []
      description << "Missing file for #{spec.spec_folder}:"
      description << "  * #{file_path.to_s.red}"
      description * "\n"
    end

    # Return a description text for an expectation that certain file paths
    # were unexpected.
    #
    # @param  [Array<Pathname>] file_paths
    #
    # @return [String]
    #
    def describe_unexpected_files(file_paths)
      description = []
      description << "Unexpected files for #{spec.spec_folder}:"
      description += file_paths.map { |f| "  * #{f.to_s.green}" }
      description * "\n"
    end

    # Return a description text for an expectation that two files were
    # expected to be the same, but are not.
    #
    # @param  [Diff] diff
    #         the diff which holds the difference
    #
    # @param  [Integer] max_width
    #         the max width of the terminal to print matching separators
    #
    # @return [String]
    #
    def describe_file_diff(diff, max_width=80)
      description = []
      description << "File comparison error `#{diff.relative_path}` for #{spec.spec_folder}:"
      description << "--- DIFF ".ljust(max_width, '-')
      description += diff.map do |line|
        case line
          when /^\+/ then line.green
          when /^-/ then  line.red
          else            line
        end.gsub("\n",'').gsub("\r", '\r')
      end
      description << "--- END ".ljust(max_width, '-')
      description << ''
      description * "\n"
    end

  end
end
