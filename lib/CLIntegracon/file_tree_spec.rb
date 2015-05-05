require 'pathname'
require 'CLIntegracon/diff'
require 'CLIntegracon/formatter'

module CLIntegracon
  class FileTreeSpec

    # @return [FileTreeSpecContext]
    #         The context, which configures path and file behaviors
    attr_reader :context

    # @return [String]
    #         The concrete spec folder
    attr_reader :spec_folder

    # @return [Pathname]
    #         The concrete spec path
    def spec_path
      context.spec_path + spec_folder
    end

    # @return [Pathname]
    #         The concrete before directory for this spec
    def before_path
      spec_path + context.before_dir
    end

    # @return [Pathname]
    #         The concrete after directory for this spec
    def after_path
      spec_path + context.after_dir
    end

    # @return [Pathname]
    #         The concrete temp directory for this spec
    def temp_path
      context.temp_path + spec_folder
    end

    # Init a spec with a given context
    #
    # @param  [FileTreeSpecContext] context
    #         The context, which configures path and file behaviors
    #
    # @param  [String] spec_folder
    #         The concrete spec folder
    #
    def initialize(context, spec_folder)
      @context = context
      @spec_folder = spec_folder
    end

    # Run this spec
    #
    # @param  [Block<(FileTreeSpec)->()>] block
    #         The block, which will be executed after chdir into the created temporary
    #         directory. In this block you will likely run your modifications to the
    #         file system and use the received FileTreeSpec instance to make asserts
    #         with the test framework of your choice.
    #
    def run(&block)
      prepare!

      copy_files!

      Dir.chdir(temp_path) do
        block.call self
      end
    end

    # Compares the expected and produced directory by using the rules
    # defined in the context
    #
    # @param  [Block<(Diff)->()>] diff_block
    #         The block, where you will likely define a test for each file to compare.
    #         It will receive a Diff of each of the expected and produced files.
    #
    def compare(&diff_block)
      transform_paths!

      glob_all(after_path).each do |relative_path|
        expected = after_path + relative_path

        next unless expected.file?

        block = special_behavior_for_path relative_path
        next if block == context.class.nop

        diff = diff_files(expected, relative_path, &block)

        diff_block.call diff
      end
    end

    # Compares the expected and produced directory by using the rules
    # defined in the context for unexpected files.
    #
    # This is separate because you probably don't want to define an extra
    # test case for each file, which wasn't expected at all. So you can
    # keep your test cases consistent.
    #
    # @param  [Block<(Array)->()>] diff_block
    #         The block, where you will likely define a test that no unexpected files exists.
    #         It will receive an Array.
    #
    def check_unexpected_files(&block)
      expected_files = glob_all after_path
      produced_files = glob_all
      unexpected_files = produced_files - expected_files

      # Select only files
      unexpected_files.select! { |path| path.file? }

      # Filter ignored paths
      unexpected_files.reject! { |path| special_behavior_for_path(path) == context.class.nop }

      block.call unexpected_files
    end

    # Return a Formatter
    #
    # @return [Formatter]
    #
    def formatter
      @formatter ||= Formatter.new(self)
    end

    protected

      # Prepare the temporary directory
      #
      def prepare!
        context.prepare!

        temp_path.rmtree if temp_path.exist?
        temp_path.mkdir
      end

      # Copies the before subdirectory of the given tests folder in the temporary
      # directory.
      #
      def copy_files!
        source = before_path
        destination = temp_path
        FileUtils.cp_r("#{source}/.", destination)
      end

      # Applies the in the context configured transformations.
      #
      def transform_paths!
        context.transform_paths.each do |path, block|
          Dir.glob(path) do |produced_path|
            produced = Pathname(produced_path)
            block.call(produced)
          end
        end
      end

      # Searches recursively for all files and take care for including hidden files
      # if this is configured in the context.
      #
      # @param  [String] path
      #         The relative or absolute path to search in (optional)
      #
      # @return [Array<Pathname>]
      #
      def glob_all(path=nil)
        Dir.chdir path || '.' do
          Dir.glob("**/*", context.include_hidden_files? ? File::FNM_DOTMATCH : 0).sort.map do |p|
            Pathname(p)
          end
        end
      end

      # Find the special behavior for a given path
      #
      # @return [Block<(Pathname) -> to_s>]
      #         This block takes the Pathname and transforms the file in a better comparable
      #         state. If it returns nil, the file is ignored.
      #
      def special_behavior_for_path(path)
        context.special_paths.each do |key, block|
          matched = if key.is_a?(Regexp)
            path.to_s.match(key)
          else
            File.fnmatch(key, path)
          end
          next unless matched
          return block
        end
        return nil
      end

      # Compares two files to check if they are identical and produces a clear diff
      # to highlight the differences.
      #
      # @param  [Pathname] expected
      #         The file in the after directory
      #
      # @param  [Pathname] relative_path
      #         The file in the temp directory
      #
      # @param  [Block<(Pathname)->(to_s)>] block
      #         the block, which transforms the files in a better comparable form
      #
      # @return [Diff]
      #         An object holding a diff
      #
      def diff_files(expected, relative_path, &block)
        produced = temp_path + relative_path
        Diff.new(expected, produced, relative_path, &block)
      end

  end
end
