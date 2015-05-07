require 'pathname'
require 'CLIntegracon/diff'
require 'CLIntegracon/formatter'

module CLIntegracon
  # FileTreeSpec represents a single specification, which is mirrored
  # on the file system in the spec directory by a direct children.
  # It contains a before directory (#before_path) and an after
  # directory (#after_path) or if it is initialized with a #base_spec,
  # the before directory of this spec is used. The before directory
  # contents in the #spec_path of the child spec, can contain further
  # files, which overwrite, if given, the inherited contents.
  #
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

    # @return [String|NilClass]
    #         The name of an optional #base_spec.
    attr_reader :base_spec_name

    # Return whether this spec is based on another spec.
    #
    # @return  [Bool]
    #
    def has_base?
      !base_spec_name.nil?
    end

    # @return [FileTreeSpec|NilClass]
    #         The spec on whose #after_path will be used as #before_path
    #         for this spec.
    def base_spec
      has_base? ? context.spec(base_spec_name) : nil
    end

    # Init a spec with a given context
    #
    # @param  [FileTreeSpecContext] context
    #         The context, which configures path and file behaviors
    #
    # @param  [String] spec_folder
    #         The concrete spec folder
    #
    # @param  [String] based_on
    #         @see #base_spec_name
    #
    def initialize(context, spec_folder, based_on: nil)
      @context = context
      @spec_folder = spec_folder
      @base_spec_name = based_on
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
        next if context.ignores?(relative_path)

        block = context.preprocessors_for(relative_path).first
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
      unexpected_files.reject! { |path| context.ignores?(path) }

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
        destination = temp_path

        if has_base?
          FileUtils.cp_r("#{base_spec.after_path}/.", destination)
        end

        begin
          FileUtils.cp_r("#{before_path}/.", destination)
        rescue Errno::ENOENT => e
          raise e unless has_base?
        end
      end

      # Applies the in the context configured transformations.
      #
      def transform_paths!
        glob_all.each do |path|
          context.transformers_for(path).each do |transformer|
            transformer.call(path)
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
