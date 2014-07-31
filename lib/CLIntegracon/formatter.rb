require 'colored'

module CLIntegracon
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
      description << "File comparison error `#{diff.expected}` for #{spec.spec_folder}:"
      description << "--- DIFF ".ljust(max_width, '-')
      description += diff.map do |line|
        case line
          when /^\+/ then line.green
          when /^-/ then  line.red
          else            line
        end.gsub("\n",'')
      end
      description << "--- END ".ljust(max_width, '-')
      description << ''
      description * "\n"
    end

  end
end
