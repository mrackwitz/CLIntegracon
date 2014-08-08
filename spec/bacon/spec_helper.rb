require 'bacon'
require 'CLIntegracon'

ROOT = Pathname.new(File.expand_path('../../../', __FILE__))
BIN  = ROOT + 'spec/fixtures/bin'

CLIntegracon.configure do |c|
  c.spec_path = ROOT + 'spec/integration'
  c.temp_path = ROOT + 'tmp/bacon_specs'

  c.hook_into :bacon
end


describe CLIntegracon::Adapter::Bacon do

  describe_cli 'coffee-maker' do

    subject do |s|
      s.name = 'coffee-maker'
      s.executable = "bundle exec ruby #{BIN}/coffeemaker.rb"
      s.environment_vars = {
          'COFFEE_MAKER_FILE' => 'Coffeemakerfile.yml'
      }
      s.default_args = [
          '--verbose',
          '--no-ansi'
      ]
      s.replace_path ROOT.to_s, 'ROOT'
      s.replace_path `bundle show claide`.rstrip, 'CLAIDE_SRC'
    end

    file_tree_spec_context do |c|
      c.ignores '.DS_Store'
      c.ignores '.gitkeep'

      c.has_special_handling_for 'execution_output.txt' do |path|
        File.read(path).gsub(/:in `<main>'$/, '') # workaround different stack trace format by ruby-1.8.7
      end
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
