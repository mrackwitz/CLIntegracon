# CLIntegracon

[![Gem](https://img.shields.io/gem/v/clintegracon.svg?style=flat)](http://rubygems.org/gems/clintegracon)
[![Build Status](https://img.shields.io/travis/mrackwitz/CLIntegracon/master.svg?style=flat)](https://travis-ci.org/mrackwitz/CLIntegracon)
[![Code Climate](https://img.shields.io/codeclimate/github/mrackwitz/CLIntegracon.svg?style=flat)](https://codeclimate.com/github/mrackwitz/CLIntegracon)
[![Dependency Status](http://img.shields.io/gemnasium/mrackwitz/CLIntegracon.svg?style=flat)](https://gemnasium.com/mrackwitz/CLIntegracon)

CLIntegracon allows you to build *Integration* specs for your *CLI*,
independent if they are based on Ruby or another technology.
It is especially useful if your command modifies the file system.
Furthermore it provides an integration for *Bacon*.

Take a look in the [documentation](http://www.rubydoc.info/github/mrackwitz/CLIntegracon/master/frames).


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
    c.spec_path = File.expand_path('../integration', __FILE__)
    c.temp_path = File.expand_path('../../tmp', __FILE__)

    # Ignore certain files ...
    c.ignores '.gitkeep'

    # ... or explicitly ignore all hidden files. (While the default is that they
    # are included in the file tree diff.)
    c.include_hidden_files = true

    c.hook_into :bacon
  end
  ```

3. Describe your specs with the extended DSL:

  ```ruby
  # Ensure that all the helpers are included in this context
  describe_cli 'coffee-maker' do

    # Setup our subject
    subject do |s|
      # Provide a display name (optional, default would be 'subject')
      s.name = 'coffee-maker'

      # Provide the real command line (required)
      s.executable = 'bundle exec ruby spec/fixtures/bin/coffeemaker.rb"'

      # Set environments variables needed on execution
      s.environment_vars = {
          'COFFEE_MAKER_FILE' => 'Coffeemakerfile.yml'
      }

      # Define default arguments
      s.default_args = [
          '--verbose',
          '--no-ansi'
      ]

      # Replace special paths in execution output by a placeholder, so that the
      # compared outputs doesn't differ dependent on the absolute location where
      # your tested CLI was executed.
      s.replace_path ROOT.to_s, 'ROOT'
    end

    describe 'Brew recipes' do

      describe 'without milk' do
        # +behaves_like+ is provided by bacon.
        # +cli_spec+ expects as first argument the directory of the spec, and
        # as second argument the arguments passed to the subject on launch.
        # The defined default arguments will be appended after that.
        # If you need to append arguments after the default arguments, because
        # of the way your command line interface is defined and how its option
        # parser works, you can pass them as third argument to +cli_spec+.
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


## Acknowledgement

This gem was inspired by the idea behind the integration tests of the
[CocoaPods](cp-main)'s main project and was integrated there.  
See [the integration in CocoaPods][cp-integration] for a real-world example with
very extensive usage of all features.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[cp-main]: https://github.com/CocoaPods/CocoaPods
[cp-integration]: https://github.com/CocoaPods/CocoaPods/blob/master/spec/integration.rb
