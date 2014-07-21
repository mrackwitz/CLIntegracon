#encoding: utf-8

require 'claide'
require 'colored'
require 'yaml'

# Don’t worry, this makes no sense, just an example
# command which modifies the file system.
class CoffeeMaker < CLAide::Command
  self.description = 'Make delicious coffee from the comfort of your terminal.'

  def self.options
    [
      ['--no-milk', 'Don’t add milk'],
      ['--sweetner=[sugar|honey]', 'Use one of the available sweetners'],
    ].concat(super)
  end

  def initialize(argv)
    @add_milk = argv.flag?('milk', true)
    @sweetner = argv.option('sweetner')
    @config_file = ENV['COFFEE_MAKER_FILE'] || 'Coffeemakerfile'
    super
  end

  def validate!
    super
    if @sweetner && !%w(sugar honey).include?(@sweetner)
      help! "'#{@sweetner}' is not a valid sweetner."
    end
  end

  def brew(recipe)
    File.open recipe+'.brewed-coffee', 'w' do |f|
      f.write "class #{recipe} < BrewedCoffee\n"
      if @add_milk
        f.write "  @milk = true\n"
      end
      if @sweetner
        f.write "  @sweetner = #{@sweetner}\n"
      end
    end
  end

  def run
    @config = YAML.load_file @config_file
    if @config['recipes'] == nil
      help! "Didn’t found any `recipes` in the Coffeemakerfile.yml."
    end
    @config['recipes'].each do |recipe|
      puts "* Brewing #{recipe}"
      brew(recipe)
    end
    puts '* Enjoy!'
  end
end

CoffeeMaker.run(ARGV)
