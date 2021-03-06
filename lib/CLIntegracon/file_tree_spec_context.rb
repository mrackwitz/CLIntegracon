require 'CLIntegracon/file_tree_spec'

module CLIntegracon
  class FileTreeSpecContext

    #-----------------------------------------------------------------------------#

    # @!group Attributes

    # @return [Pathname]
    #         The relative path to the integration specs
    attr_accessor :spec_path

    # @return [Pathname]
    #         The relative path from a concrete spec directory to the directory containing the input files,
    #         which will be available at execution
    attr_accessor :before_dir

    # @return [Pathname]
    #         The relative path from a concrete spec directory to the directory containing the expected files after
    #         the execution
    attr_accessor :after_dir

    # @return [Pathname]
    #         The relative path to the directory containing the produced files after the
    #         execution. This must not be the same as the before_dir or the after_dir.
    #
    # @note   **Attention**: This path will been deleted before running to ensure a clean sandbox for testing.
    #
    attr_accessor :temp_path

    # @return [Hash<String|Regexp,Block>]
    #         the paths of files, which need to be transformed in a better comparable form
    attr_accessor :transform_paths

    # @return [Hash<String|Regexp,Block>]
    #         the paths of files, where an individual file diff handling is needed
    attr_accessor :preprocess_paths

    # @return [Array<String|Regexp>]
    #         the paths of files to exclude from comparison
    attr_accessor :ignore_paths

    # @return [Bool]
    #         whether to include hidden files, when searching directories (true by default)
    attr_accessor :include_hidden_files
    alias :include_hidden_files? :include_hidden_files


    #-----------------------------------------------------------------------------#

    # @!group Initializer

    # "Designated" initializer
    #
    # @param  [Hash<Symbol,String>] properties
    #         The configuration parameter (optional):
    #         :spec_path   => see self.spec_path
    #         :before_dir  => see self.before_dir
    #         :after_dir   => see self.after_dir
    #         :temp_path   => see self.temp_path
    #
    def initialize(properties={})
      self.spec_path   = properties[:spec_path]   || '.'
      self.temp_path   = properties[:temp_path]   || 'tmp'
      self.before_dir  = properties[:before_dir]  || 'before'
      self.after_dir   = properties[:after_dir]   || 'after'
      self.transform_paths = {}
      self.preprocess_paths = {}
      self.ignore_paths = []
      self.include_hidden_files = true
    end


    #-----------------------------------------------------------------------------#

    # @!group Setter

    def spec_path=(spec_path)
      # Spec dir has to exist.
      @spec_path= Pathname(spec_path).realpath
    end

    def temp_path=(temp_path)
      # Temp dir, doesn't have to exist itself, it will been created, but let's ensure
      # that at least the last but one path component exist.
      raise "temp_path's parent directory doesn't exist" unless (Pathname(temp_path) + '..').exist?
      @temp_path = Pathname(temp_path)
    end

    def before_dir=(before_dir)
      @before_dir = Pathname(before_dir)
    end

    def after_dir=(after_dir)
      @after_dir = Pathname(after_dir)
    end


    #-----------------------------------------------------------------------------#

    # @!group DSL-like Setter

    # Registers a block to transform certain files, matched with globs or
    # regular expressions.
    # Multiple transformers can match a single file.
    #
    # @param  [String...] file_paths
    #         The path(s), which need to be transformed in a better comparable form
    #
    # @param  [Block<(Pathname) -> ()>] block
    #         The block, which takes each of the matched files, transforms it if needed
    #         in a better comparable form in the temporary path, so that the temporary
    #         will be compared to a given after file, or makes appropriate expects, which
    #         depend on the used test framework
    #
    def transform_produced(*file_paths, &block)
      file_paths.each do |file_path|
        self.transform_paths[file_path] = block
      end
    end

    # Registers a block to preprocess certain files, matched with globs or
    # regular expressions.
    # Registered file paths will be excluded from default comparison by `diff`.
    # A file is preprocessed with the first matching preprocessor.
    #
    # @param  [String|Regexp...] file_paths
    #         The path(s)s, where an individual file diff handling is needed
    #
    # @param  [Block<(Pathname) -> (String)>] block
    #         The block, which takes each of the matched files, transforms it if needed
    #         in a better comparable form.
    #
    def preprocess(*file_paths, &block)
      file_paths.each do |file_path|
        self.preprocess_paths[file_path] = block
      end
    end

    # Copies the before subdirectory of the given tests folder in the temporary
    # directory.
    #
    # @param  [String|RegExp...] file_paths
    #         the file path(s) of the files to exclude from comparison
    #
    def ignores(*file_paths)
      self.ignore_paths += file_paths
    end


    #-----------------------------------------------------------------------------#

    # @!group Path accessors

    # Returns a list of transformers to apply for a given file path.
    #
    # @param  [Pathname] file_path
    #         The file path to match
    #
    # @return [Array<Block<(Pathname) -> ()>>]
    #
    def transformers_for(file_path)
      select_matching_file_patterns(transform_paths, file_path).values
    end

    # Returns a list of preprocessors to apply for a given file path.
    #
    # @param  [Pathname] file_path
    #         The file path to match
    #
    # @return [Array<Block<(Pathname) -> (String)>>]
    #
    def preprocessors_for(file_path)
      select_matching_file_patterns(preprocess_paths, file_path).values
    end

    # Checks whether a given file path is to ignore.
    #
    # @param  [Pathname] file_path
    #         The file path to match
    #
    # @return [Bool]
    #
    def ignores?(file_path)
      !select_matching_file_patterns(ignore_paths, file_path).empty?
    end


    #-----------------------------------------------------------------------------#

    # @!group Interaction

    # Prepare the temporary directory and the attribute #temp_path itself.
    #
    def prepare!
      temp_path.mkpath
      @temp_path = temp_path.realpath
    end

    # Get a specific spec with given folder to run it
    #
    # @param  [String] folder
    #         The name of the folder of the tests
    #
    # @param  [String] based_on
    #         @see FileTreeSpec#base_spec_name
    #
    # @return [FileTreeSpec]
    #
    def spec(spec_folder, based_on: nil)
      FileTreeSpec.new(self, spec_folder, based_on: based_on)
    end

    #-----------------------------------------------------------------------------#

    private

    # @!group Helpers

    # Select elements in an enumerable which match the given path.
    #
    # @param  [Enumerable<String|RegExp>] patterns
    #         The patterns to check
    #
    # @param  [Pathname] path
    #         The file to match
    #
    # @return [Enumerable<String|RegExp>]
    #
    def select_matching_file_patterns(patterns, path)
      patterns.select do |pattern|
        if pattern.is_a?(Regexp)
          path.to_s.match(pattern)
        else
          flags = File::FNM_PATHNAME
          flags |= File::FNM_DOTMATCH if include_hidden_files?
          File.fnmatch(pattern, path, flags)
        end
      end
    end

  end
end
