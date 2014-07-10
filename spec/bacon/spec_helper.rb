require 'bacon'
require 'CLIntegracon'

ROOT = Pathname.new(File.expand_path('../../../', __FILE__))

CLIntegracon.configure do |c|
  c.context.spec_dir = Pathname(File.expand_path('..', __FILE__))
  c.context.temp_dir = Pathname(File.expand_path('../../../tmp/bacon_specs', __FILE__))

  c.hook_into :bacon
end


describe CLIntegracon::Adapter::Bacon do

  describe_cli 'bundle' do

    subject do
      CLIntegracon::Subject.new('bundle', 'bundle exec bundle').tap do |subject|
        subject.environment_vars = {
            #'BUNDLE_GEMFILE' => 'Jewelfile'
        }
        subject.default_args = [
            '--verbose',
            '--no-color'
        ]
        subject.has_special_path ROOT.to_s, 'ROOT'
      end
    end

    context do
      ignores '**/.git/**'
    end

    describe 'gem' do

      describe 'Create a simple gem, suitable for development with bundler' do
        behaves_like_a 'bundle', args: 'gem Test', dir: 'gem'
      end

    end

  end

end
