require 'CLIntegracon/file_tree_spec'

module CLIntegracon
  class FileTreeSpecContext

    #-----------------------------------------------------------------------------#

    # @!group Attributes

    # @return [Pathname]
    #         The relative path to the integration specs
    attr_accessor :spec_dir

    # @return [Pathname]
    #         The relative path from a concrete spec directory to the directory containing the input files,
    #         which will be available at execution
    attr_accessor :before_dir

    # @return [Pathname]
    #         The relative path from a concrete spec directory to the directory containing the expected files after
    #         the execution
    attr_accessor :after_dir

    # @return [Pathname]
    #         The relative path from a concrete spec directory to the directory containing the produced files after
    #         the execution. This must not be the same as the before_dir or the after_dir.
    attr_accessor :temp_dir

    # @return [Proc] The proc generating specs in the given DSL (RSpec, Bacon, …)
    attr_accessor :spec_generator

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
    #        :spec_dir    => see self.spec_dir
    #        :before_dir  => see self.before_dir
    #        :after_dir   => see self.after_dir
    #        :temp_dir    => see self.temp_dir
    #
    # @param [Block<(Pathname,Pathname,Bool,String) -> ()>] block
    #        The block, which adapts to the used test framework. It expects the following arguments:
    #        * expected: the path of the expected file
    #        * produced: the path found in the temporary directory
    #        * is_equal: whether the files are equal
    #        * diff_output: the output of the diff
    #
    def initialize(properties={}, &spec_generator)
      self.spec_dir    = (properties[:spec_dir]    || Pathname('.')).realpath
      self.before_dir  = properties[:before_dir]  || Pathname('before')
      self.after_dir   = properties[:after_dir]   || Pathname('after')
      self.temp_dir    = (properties[:temp_dir]    || Pathname('tmp')).realdirpath
      self.spec_generator = spec_generator
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

    # Run a specific spec with given folder
    #
    # @param [String] folder
    #        The name of the folder of the tests
    #
    # @param [Block<(FileTreeSpec)->()>] block
    #        The block, which will be executed after chdir into the created temporary
    #        directory. In this block you will likely run your modifications to the
    #        file system and use the received FileTreeSpec instance to make asserts
    #        with the test framework of your choice.
    #
    def run(spec_folder, &block)
      temp_dir.rmtree if temp_dir.exist?
      temp_dir.mkpath

      copy_files(spec_folder)

      Dir.chdir(temp_dir + spec_folder) do
        block.call FileTreeSpec.new(self, spec_folder)
      end
    end


    #-----------------------------------------------------------------------------#

    # @!group Helper

    protected

      # Copies the before subdirectory of the given tests folder in the temporary
      # directory.
      #
      # @param [String] folder
      #        The name of the folder of the tests
      #
      def copy_files(folder)
        source = spec_dir + Pathname(folder.to_s) + before_dir
        destination = temp_dir + folder
        destination.mkpath
        FileUtils.cp_r(Dir.glob("#{source}/*"), destination)
      end

  end
end
