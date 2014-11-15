module CLIntegracon
  class Subject

    #-----------------------------------------------------------------------------#

    # @!group Attributes

    # @return [String]
    #         The name of the binary to use for the tests
    attr_accessor :name

    # @return [String]
    #         The executable statement to use for the tests
    attr_accessor :executable

    # @return [Hash<String,String>]
    #         The environment variables which will always been defined for the executable
    #         on launch should not been passed explicitly every time to the launch method.
    attr_accessor :environment_vars

    # @return [Array<String>]
    #         The arguments which will always passed to the executable on launch and
    #         should not been passed explicitly every time to the launch method.
    #         Those are added behind the arguments given on +launch+.
    attr_accessor :default_args

    # @return [Hash<String|Regexp,String>]
    #         The replace patterns, whose keys are expected to occur in the output,
    #         which should been redacted, when the subject will be executed. These are
    #         e.g. paths were side-effects occur, like manipulation of user configurations
    #         in dot files or caching-specific directories or just dates and times.
    attr_accessor :replace_patterns

    # @return [String]
    #         The path where the output of the executable will be written to.
    attr_accessor :output_path


    #-----------------------------------------------------------------------------#

    # @!group Initializer

    # "Designated" initializer
    #
    # @param [String] name
    #        The name of the binary
    #
    # @param [String] executable
    #        The executable subject statement (optional)
    #
    def initialize(name='subject', executable=nil)
      self.name = name
      self.executable = executable || name
      self.environment_vars = {}
      self.default_args = []
      self.replace_patterns = {}
      self.output_path = 'execution_output.txt'
    end


    #-----------------------------------------------------------------------------#

    # @!group DSL-like Setter

    # Define a pattern, whose occurrences in the output should been replaced a
    # given placeholder.
    #
    # @param [Regexp|String] pattern
    #        The pattern
    #
    # @param [String] replacement
    #        The replacement
    #
    def replace_pattern(pattern, replacement)
      self.replace_patterns[replacement] = pattern
    end

    # Define a path, whose occurrences in the output should been replaced by
    # either its basename or a given placeholder.
    #
    # @param [String] path
    #        The path
    #
    # @param [String] name
    #        The name of the path, or the basename of the given path
    #
    def replace_path(path, name=nil)
      name ||= File.basename path
      self.replace_pattern path, name
    end

    # Define a path in the user directory, whose occurrences in the output
    # should been replaced by either its basename or a given placeholder.
    #
    # @param [String] path
    #        The path
    #
    # @param [String] name
    #        The name of the path, or the given path
    #
    def replace_user_path(path, name=nil)
      name ||= "$HOME/#{path}"
      self.replace_path %r[/Users/.*/#{path.to_s}], name
    end

    #-----------------------------------------------------------------------------#

    # @!group Interaction

    # Runs the executable with the given arguments.
    #
    # @note: You can check by `$?.success?` if the execution succeeded.
    #
    # @param  [String] head_arguments
    #         The arguments to pass to the executable before the default arguments.
    #
    # @param  [String] tail_arguments
    #         The arguments to pass to the executable after the default arguments.
    #
    # @return [String]
    #         The output, which is emitted while execution.
    #
    def launch(head_arguments='', tail_arguments='')
      command = command_line(head_arguments, tail_arguments)
      output = apply_replacements(run(command))
      write_output(command, output)
      output
    end

    #-----------------------------------------------------------------------------#

    # @!group Helpers

    protected

    # Serializes configured environment variables
    #
    # @return [String]
    #         Serialized assignment of configured environment variables.
    #
    def environment_var_assignments
      environment_vars.map { |key,value| "#{key}=#{value}" }.join ' '
    end

    # Run the command.
    #
    # @param  [String] command_line
    #         THe command line to execute
    #
    # @return [String]
    #         The output, which is emitted while execution.
    #
    def run(command_line)
      `#{environment_var_assignments} #{command_line} 2>&1`
    end

    # Merges the given with the configured arguments and returns the command
    # line to execute.
    #
    # @param  [String] head_arguments
    #         The arguments to pass to the executable before the default arguments.
    #
    # @param  [String] tail_arguments
    #         The arguments to pass to the executable after the default arguments.
    #
    # @return [String]
    #         The command line to execute.
    #
    def command_line(head_arguments='', tail_arguments='')
      args = [head_arguments, default_args, tail_arguments].flatten.compact.select { |s| s.length > 0 }.join ' '
      "#{executable} #{args}"
    end

    # Apply the configured replacements to the output.
    #
    # @param  [String] output
    #         The output, which was emitted while execution.
    #
    # @return [String]
    #         The redacted output.
    #
    def apply_replacements(output)
      replace_patterns.each do |key, path|
        output = output.gsub(path, key)
      end
      output
    end

    # Saves the output in a file called #output_path, relative to current dir.
    #
    # @param  [String] command
    #         The executed command line.
    #
    # @param  [String] output
    #         The output, which was emitted while execution.
    #
    def write_output(command, output)
      File.open(output_path, 'w') do |file|
        printable_command = "#{environment_var_assignments} #{command} 2>&1"
        file.write printable_command.sub(executable, name)
        file.write "\n"
        file.write output
      end
    end

  end
end
