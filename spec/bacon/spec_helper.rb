require 'bacon'
require 'CLIntegracon'

ROOT = Pathname.new(File.expand_path('../../../', __FILE__))
BIN  = ROOT + 'spec/fixtures/bin'

CLIntegracon.configure do |c|
  c.context.spec_dir = ROOT + 'spec/integration'
  c.context.temp_dir = ROOT + 'tmp/bacon_specs'

  c.hook_into :bacon
end


describe CLIntegracon::Adapter::Bacon do

  describe_cli 'coffee-maker' do

    subject do
      CLIntegracon::Subject.new('coffee-maker', "bundle exec ruby #{BIN}/coffeemaker.rb").tap do |subject|
        subject.environment_vars = {
            'COFFEE_MAKER_FILE' => 'Coffeemakerfile.yml'
        }
        subject.default_args = [
            '--verbose',
            '--no-ansi'
        ]
        subject.has_special_path ROOT.to_s, 'ROOT'
      end
    end

    context do
      ignores '.gitkeep'
    end

    describe 'Brew recipes' do

      describe 'without milk' do
        behaves_like cli_spec('coffeemaker_no_milk', '--no-milk')
      end

      describe 'with honey as sweetner' do
        behaves_like cli_spec('coffeemaker_sweetner_honey', '--sweetner=honey')
      end

    end

    describe 'Get help' do
      behaves_like cli_spec('coffeemaker_help', '--help')
    end

  end

end
