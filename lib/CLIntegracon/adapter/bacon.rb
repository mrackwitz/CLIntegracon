require 'colored'

# Layout structure
module CLIntegracon
  module Adapter
  end
end

# Define concrete adapter
module CLIntegracon::Adapter::Bacon
  module Context

    # Get or configure the current subject
    #
    # @note On first call this will create a new subject on base of the
    #       shared configuration and store it in the ivar `@subject`.
    #
    # @param  [Block<(Subject) -> ()>]
    #         This block, if given, will be evaluated on the caller.
    #         It receives as first argument the subject itself.
    #
    # @return [Subject]
    #         the subject
    #
    def subject &block
      @subject ||= CLIntegracon::shared_config.subject.dup
      return @subject if block.nil?
      instance_exec(@subject, &block)
    end

    # Get or configure the current context for FileTreeSpecs
    #
    # @note On first call this will create a new context on base of the
    #       shared configuration and store it in the ivar `@file_tree_spec_context`.
    #
    # @param  [Block<(FileTreeSpecContext) -> ()>]
    #         This block, if given, will be evaluated on the caller.
    #         It receives as first argument the context itself.
    #
    # @return [FileTreeSpecContext]
    #         the spec context, will be lazily created if not already present.
    #
    def file_tree_spec_context &block
      @file_tree_spec_context ||= CLIntegracon.shared_config.file_tree_spec_context.dup
      return @file_tree_spec_context if block.nil?
      instance_exec(@file_tree_spec_context, &block)
    end

    # Works like `behaves_like`, but takes arguments for the shared example
    #
    # @param  [String] name
    #         name of the shared context.
    #
    # @param  [...] args
    #         params to pass to the shared context
    #
    def behaves_like_a(name, *args)
      instance_exec(*args, &Bacon::Shared[name])
    end

    # Ad-hoc defines a set of shared expectations to be consumed directly by `behaves_like`.
    # See the following example for usage:
    #
    #   behaves_like cli_spec('my_spec_dir', 'install --verbose')
    #
    # @note    This expects that a method `file_tree_spec_context` is defined, which is
    #          returning an instance of {FileTreeSpecContext}.
    #
    # @param   [String] spec_dir
    #          the concrete directory of the spec, see {file_spec}.
    #
    # @param   [String] head_args
    #          the arguments to pass before the +default_args+ on launch to {CLIntegracon::Subject}.
    #
    # @param   [String] tail_args
    #          the arguments to pass after the +default_args+ on launch to {CLIntegracon::Subject}.
    #
    # @param   [String] based_on
    #          Allows to specify an optional base spec, whose after directory will be used
    #          as before directory. You have to ensure that the specs are defined in order,
    #          so that the base spec was executed before.
    #
    # @return  [String]
    #          name of the set of shared expectations
    #
    def cli_spec(spec_dir, head_args=nil, tail_args=nil, based_on: nil)
      file_spec(spec_dir, based_on: based_on) do
        output, status = subject.launch(head_args, tail_args)

        args = [head_args, tail_args].compact
        it "$ #{subject.name} #{args.join(' ')}" do
          status.should.satisfy("Binary failed\n\n#{output}") do
            status.success?
          end
        end
        status.success?
      end
    end

    # Ad-hoc defines a set of shared expectations to be consumed directly by `behaves_like`.
    # See the following example for usage:
    #
    #   behaves_like file_spec('my_spec_dir') do
    #     # do some changes to the current dir
    #   end
    #
    # @note    This expects that a method `file_tree_spec_context` is defined, which is
    #          returning an instance of {FileTreeSpecContext}.
    #
    # @param   [String] spec_dir
    #          the concrete directory of the spec to be passed to
    #          {FileTreeSpecContext.spec}
    #
    # @param   [String] based_on
    #          Allows to specify an optional base spec, whose after directory will be used
    #          as before directory.
    #
    # @param   [Block<() -> ()>] block
    #          the block which will be executed after the before state is laid out in the
    #          temporary directory, which normally will make modifications to file system,
    #          which will be compare to the state given in the after directory.
    #
    # @return  [String]
    #          name of the set of shared expectations
    #
    def file_spec(spec_dir, based_on: nil, &block)
      raise ArgumentError.new("Spec directory is missing!") if spec_dir.nil?

      shared_name = spec_dir

      shared shared_name do
        file_tree_spec_context.spec(spec_dir, based_on: based_on).run do |spec|
          break unless instance_eval &block

          formatter = spec.formatter.lazy

          spec.compare do |diff|
            it diff.relative_path.to_s do
              diff.produced.should.satisfy(formatter.describe_missing_file(diff.relative_path)) do
                diff.produced.exist?
              end

              diff.produced.should.satisfy(formatter.describe_file_diff(diff)) do
                diff.is_equal?
              end

              diff.produced.should.satisfy(formatter.describe_file_permission_diff(diff)) do
                diff.have_equal_permissions?
              end
            end
          end

          spec.check_unexpected_files do |files|
            it "should not produce unexpected files" do
              files.should.satisfy(formatter.describe_unexpected_files(files)) do
                files.size == 0
              end
            end
          end
        end
      end

      shared_name
    end

  end

  # Describe a command line interface
  # This method basically behaves like {Bacon::Context.describe}, but it provides
  # automatically the methods #subject, #file_tree_spec_context, #cli_spec and #file_spec.
  #
  # @param  [String] subject_name
  #         the subject name will be used as first argument to initialize
  #         a new {CLIntegracon::Subject}, which will be accessible in the
  #         spec by #subject.
  #
  # @param  [Hash<Symbol,String>] context_options
  #         the options to configure this spec context, could be one or more of:
  #         * :executable: the executable used to initialize {CLIntegracon::Subject}
  #           if not given, will fallback to param {subject_name}.
  #
  # @param  [Block<() -> ()>] block
  #         the block to provide further sub-specs or requirements, as
  #         known from {Bacon::Context.describe}
  #
  def describe_cli(subject_name, context_options = {}, &block)
    context = describe subject_name do
      # Make Context methods available
      # WORKAROUND: Bacon auto-inherits singleton methods to child contexts
      # by using the runtime and won't include methods in modules included
      # by the parent context. We have to ensure that the methods will be
      # accessible by the child contexts by defining them as singleton methods.
      extended = self.extend Context
      Context.instance_methods.each do |method|
        class << self; self end.instance_eval do
          unbound_method = extended.method(method).unbind

          send :define_method, method do |*args, &b|
            unbound_method.bind(self).call(*args, &b)
          end
        end
      end

      subject do |s|
        s.name       = subject_name
        s.executable = context_options[:executable] || subject_name
      end

      instance_eval &block
    end

    Bacon::ErrorLog.gsub! %r{^.*lib/CLIntegracon/.*\n}, ''

    context
  end

end

# Make #describe_cli global available
extend CLIntegracon::Adapter::Bacon

# Patch Bacon::Context to support #describe_cli
module Bacon
  class Context
    include CLIntegracon::Adapter::Bacon
  end
end
