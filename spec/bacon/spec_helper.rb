require 'bacon'
require 'CLIntegracon'
require 'colored'

ROOT = Pathname.new(File.expand_path('../../', __FILE__))


module Bacon
  class Context
    # Works like `behaves_like`, but takes arguments for the shared example
    def behaves_like_a(name, *args)
      instance_eval { Shared[name].call(*args) }
    end
  end
end


describe "Integration" do

  context = CLIntegracon::FileTreeSpecContext.new(spec_dir: Pathname(File.expand_path('..', __FILE__))).tap do |context|
    context.ignores '**/.git/**'
  end

  subject = CLIntegracon::Subject.new('bundle', 'bundle exec bundle').tap do |subject|
    subject.environment_vars = {
        #'BUNDLE_GEMFILE' => 'Jewelfile'
    }
    subject.default_args = [
        '--verbose',
        '--no-color'
    ]
    subject.has_special_path ROOT.to_s, 'ROOT'
  end

  shared 'CLI' do |args, spec_folder|
    raise ArgumentError.new "Spec folder is missing!" if spec_folder.nil?

    context.run spec_folder do |spec|
      subject.launch args do |status, output|
        it "$ #{subject.name} #{args}" do
          status.should.satisfy("Binary failed\n\n#{output}") do
            status.success?
          end
        end
      end

      spec.compare do |diff|
        it diff.expected.to_s do
          diff.produced.should.exist?

          description = []
          description << "File comparison error `#{diff.expected}`"
          description << ""
          description << diff.pretty_print

          diff.produced.should.satisfy(description * "\n") do
            diff.is_equal?
          end
        end
      end

      spec.check_unexpected_files do |files|
        it "should not produce unexpected files" do
          description = []
          description << "Unexpected files:"
          description += files.map { |f| "  * #{f.to_s.green}" }

          files.should.satisfy(description * "\n") do
            files.size == 0
          end
        end
      end
    end
  end


  describe 'bundle' do

    describe 'gem' do

      describe 'Create a simple gem, suitable for development with bundler' do
        behaves_like_a 'CLI', 'gem Test', 'gem'
      end

    end

  end

end
