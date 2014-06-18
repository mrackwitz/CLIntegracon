require 'bacon'
require 'CLIntegracon'

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

  context = CLIntegracon::FileTreeSpecContext.new

  subject = CLIntegracon::Subject.new('$ git', 'git').tap do |subject|
    subject.environment_vars = {
        'GIT_INDEX_FILE' => '.fool/custom-index',
    }
    subject.default_args = [
        '--git-dir=.fool',
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
        relative_path = diff.expected.relative_path_from(context.spec_dir)

        it relative_path.to_s do
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
          files.size.should.equal 0
        end
      end
    end
  end


  describe 'git' do

    describe 'init' do

      describe 'Initializes a new repository' do
        behaves_like_a 'CLI', 'init', 'init'
      end

    end

  end

end
