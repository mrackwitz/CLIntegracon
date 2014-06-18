require 'pathname'
require 'CLIntegracon/diff'

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
      context.spec_dir + spec_folder
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

    # Init a spec with a given context
    #
    # @param [FileTreeSpecContext] context
    #        The context, which configures path and file behaviors
    #
    # @param [String] spec_folder
    #        The concrete spec folder
    #
    def initialize(context, spec_folder)
      @context = context
      @spec_folder = spec_folder
    end

    # Compares the expected and produced directory by using the rules
    # defined in the context
    #
    # @param [Block<(Diff)->()>] diff_block
    #        The block, where you will likely define a test for each file to compare.
    #        It will receive a Diff of each of the expected and produced files.
    #
    def compare(&diff_block)
      self.context.transform_paths.each do |path, block|
        Dir.glob(path) do |produced_path|
          produced = Pathname(produced_path)
          block.call(produced)
        end
      end

      Dir.glob("#{after_path}/**/*") do |expected_path|
        expected = Pathname(expected_path)
        next unless expected.file?

        relative_path = expected.relative_path_from(after_path)
        produced = context.temp_dir + spec_folder + relative_path

        diff = diff_files(expected, produced)

        context.special_paths.each do |key, block|
          matched = key.respond_to?(:match) ? key.match(produced.to_s) : key == produced
          next unless matched
          diff.preparator = block
          break
        end

        next if diff.preparator == context.class.nop

        diff_block.call diff
      end
    end

    protected

      # Compares two files to check if they are identical and produces a clear diff
      # to highlight the differences.
      #
      # @param [Pathname] expected
      #        The file in the after directory
      #
      # @param [Pathname] produced
      #        The file in the temp directory
      #
      # @return [Diff]
      #         An object holding a diff
      #
      def diff_files(expected, produced)
        Diff.new(expected, produced)
      end

  end
end
