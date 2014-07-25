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

    # @return [Hash<String,Block>]
    #         the special paths of files, which need to be transformed in a better comparable form
    attr_accessor :transform_paths

    # @return [Hash<String,Block>]
    #         the special paths of files, where an individual file diff handling is needed
    attr_accessor :special_paths

    # @return [Bool]
    #         whether to include hidden files, when searching directories (true by default)
    attr_accessor :include_hidden_files
    alias :include_hidden_files? :include_hidden_files


    #-----------------------------------------------------------------------------#

    # @!group Initializer

    # "Designated" initializer
    #
    # @param [Hash<Symbol,String>] properties
    #        The configuration parameter (optional):
    #        :spec_path   => see self.spec_path
    #        :before_dir  => see self.before_dir
    #        :after_dir   => see self.after_dir
    #        :temp_path   => see self.temp_path
    #
    def initialize(properties={})
      self.spec_path   = properties[:spec_path]   || '.'
      self.temp_path   = properties[:temp_path]   || 'tmp'
      self.before_dir  = properties[:before_dir]  || 'before'
      self.after_dir   = properties[:after_dir]   || 'after'
      self.transform_paths = {}
      self.special_paths = {}
      self.include_hidden_files = true
    end


    #-----------------------------------------------------------------------------#

    # @!group Helper

    # This value is used for ignored paths
    #
    # @return [Proc]
    #         Does nothing
    def self.nop
      @nop ||= Proc.new {}
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
      @temp_path = Pathname(temp_path).realpath
    end

    def before_dir=(before_dir)
      @before_dir = Pathname(before_dir)
    end

    def after_dir=(after_dir)
      @after_dir = Pathname(after_dir)
    end


    #-----------------------------------------------------------------------------#

    # @!group DSL-like Setter

    # Registers a block for special handling certain files, matched with globs.
    # Multiple transformers can match a single file.
    #
    # @param  [String...] file_paths
    #         The file path(s) of the files, which were created/changed and need transformation
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

    # Registers a block for special handling certain files, matched with globs.
    # Registered file paths will be excluded from default comparison by `diff`.
    # Multiple special handlers can match a single file.
    #
    # @param  [String|Regexp...] file_paths
    #         The file path(s) of the files, which were created/changed and need special comparison
    #
    # @param  [Block<(Pathname) -> (String)>] block
    #         The block, which takes each of the matched files, transforms it if needed
    #         in a better comparable form.
    #
    def has_special_handling_for(*file_paths, &block)
      file_paths.each do |file_path|
        self.special_paths[file_path] = block
      end
    end

    # Copies the before subdirectory of the given tests folder in the temporary
    # directory.
    #
    # @param  [String] file_path
    #         the file path of the files, which were changed and need special comparison
    #
    def ignores(file_path)
      self.special_paths[file_path] = self.class.nop
    end


    #-----------------------------------------------------------------------------#

    # @!group Interaction

    # Prepare the temporary directory
    #
    def prepare!
      temp_path.mkpath
    end

    # Get a specific spec with given folder to run it
    #
    # @param [String] folder
    #        The name of the folder of the tests
    #
    # @return [FileTreeSpec]
    #
    def spec(spec_folder)
      FileTreeSpec.new(self, spec_folder)
    end

  end
end
