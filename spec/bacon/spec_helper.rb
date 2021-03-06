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
          'COFFEE_MAKER_FILE' => 'Coffeemakerfile.yml',
          'PROJECT_DIR'       => ROOT,
      }
      s.default_args = [
          '--verbose',
          '--no-ansi'
      ]
      s.replace_path ROOT.to_s, 'ROOT'
    end

    file_tree_spec_context do |c|
      c.ignores '.DS_Store'
      c.ignores '.gitkeep'

      c.transform_produced /\.brewed-coffee/ do |path|
        FileUtils.touch("#{path}.decanted")
      end

      c.preprocess 'CaPheSuaDa.brewed-coffee' do |path|
        File.read(path)
      end
    end

    describe 'Brew recipes' do

      describe 'without milk' do
        behaves_like cli_spec('coffeemaker_no_milk', '--no-milk')
      end

      describe 'with honey as sweetner' do
        behaves_like cli_spec('coffeemaker_sweetner_honey', '--sweetner=honey')
      end

      describe 'without milk and honey as sweetner' do
        behaves_like cli_spec('coffeemaker_no_milk_sweetner_honey', '--no-milk --sweetner=honey',
                              based_on: 'coffeemaker_sweetner_honey')
      end

    end

    describe 'Get help' do
      behaves_like cli_spec('coffeemaker_help', '--help')
    end

  end

end
