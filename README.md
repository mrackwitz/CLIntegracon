# CLIntegracon

[![Gem](https://img.shields.io/gem/v/clintegracon.svg?style=flat)](http://rubygems.org/gems/clintegracon)
[![Build Status](https://img.shields.io/travis/mrackwitz/CLIntegracon/master.svg?style=flat)](https://travis-ci.org/mrackwitz/CLIntegracon)
[![Coverage](https://img.shields.io/codeclimate/coverage/github/mrackwitz/CLIntegracon.svg?style=flat)](https://codeclimate.com/github/mrackwitz/CLIntegracon)
[![Code Climate](https://img.shields.io/codeclimate/github/mrackwitz/CLIntegracon.svg?style=flat)](https://codeclimate.com/github/mrackwitz/CLIntegracon)

CLIntegracon allows you to build *Integration* specs for your *CLI*,
independent if they are based on Ruby or another technology.
It is especially useful if your command modifies the file system.
Furthermore it provides an integration for *Bacon*.


## Installation

Add this line to your application's Gemfile:

    gem 'clintegracon'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install clintegracon


## Usage

This description assumes the following file system layout of your CLI project.
This is not fixed, but if yours differ, you have to change paths accordingly.

```
─┬─/ (root)
 │
 ├─┬─spec
 │ ├───spec_helper.rb
 │ └─┬─integration
 │   ├─┬─arg1
 │   │ ├─┬─before
 │   │ │ ├───source.h
 │   │ │ └───source.c
 │   │ └─┬─after
 │   │   ├───execution_output.txt
 │   │   ├───source.h
 │   │   ├───source.c
 │   │   └───source.o
 │   └─┬─arg2
 │     ├─┬─before
 │     │ …
 │     └─┬─after
 │       …
 └───tmp
```

### Bacon

1. Include CLIntegracon in your *spec_helper.rb*

  ```ruby
  require 'CLIntegracon'
  ```

2. Setup the basic configuration and hook into Bacon as test framework:

  ```ruby
  CLIntegracon.configure do |c|
    c.context.spec_dir = Pathname(File.expand_path('../integration', __FILE__))
    c.context.temp_dir = Pathname(File.expand_path('../tmp', __FILE__))

    c.hook_into :bacon
  end
  ```

3. Describe your specs with the extended DSL:

  ```ruby
  # Ensure that all the helpers are included in this context
  describe_cli 'coffee-maker' do

      subject do
        # Setup our subject and provide a display name, and the real command line
        CLIntegracon::Subject.new('coffee-maker', "bundle exec ruby spec/fixtures/bin/coffeemaker.rb").tap do |subject|
          # Set environments variables needed on execution
          subject.environment_vars = {
              'COFFEE_MAKER_FILE' => 'Coffeemakerfile.yml'
          }

          # Define default arguments
          subject.default_args = [
              '--verbose',
              '--no-ansi'
          ]

          # Replace special paths in execution output by a placeholder, so that the
          # compared outputs doesn't differ dependent on the absolute location where
          # your tested CLI was executed.
          subject.has_special_path ROOT.to_s, 'ROOT'
        end
      end

      context do
        # Ignore certain files ...
        ignores '.gitkeep'

        # ... or explicitly ignore all hidden files. (While the default is that they
        # are included in the file tree diff.)
        include_hidden_files = true
      end

      describe 'Brew recipes' do

        describe 'without milk' do
          # +behaves_like+ is provided by bacon.
          # +cli_spec+ expects as first argument the directory of the spec, and
          # as second argument the arguments passed to the subject on launch.
          behaves_like cli_spec('coffeemaker_no_milk', '--no-milk')

          # Implementation details:
          # +cli_spec+ will define on-the-fly a new shared set of expectations
          # and will return its name and pass it to +behaves_like+, so that it
          # will be immediately executed.
        end

        describe 'with honey as sweetner' do
          behaves_like cli_spec('coffeemaker_sweetner_honey', '--sweetner=honey')
        end

      end

      describe 'Get help' do
        behaves_like cli_spec('coffeemaker_help', '--help')
      end

  end
  ```

4. Profit

  ![Bacon Example Terminal Output](/../assets/term-output-bacon.png?raw=true)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
