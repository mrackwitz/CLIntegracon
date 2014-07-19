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
    attr_accessor :default_args

    # @return [Hash<String,String>]
    #         The special paths, which are not relative to the project, when the statement
    #         will be executed. These are paths were side-effects occur, like manipulation
    #         of user configurations in dot files or caching-specific directories.
    attr_accessor :special_paths

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
    def initialize(name, executable=nil)
      self.name = name
      self.executable = executable || name
      self.environment_vars = {}
      self.default_args = []
      self.special_paths = {}
      self.output_path = 'execution_output.txt'
    end


    #-----------------------------------------------------------------------------#

    # @!group DSL-like Setter

    # Define a path in the user directory as special path
    #
    # @param [String] path
    #        The path
    #
    # @param [String] name
    #        The name of the path, or the basename of the given path
    #
    def has_special_path(path, name=nil)
      name ||= File.basename path
      self.special_paths[name] = path
    end

    # Define a path in the user directory as special path
    #
    # @param [String] path
    #        The path
    #
    # @param [String] name
    #        The name of the path, or the basename of the given path
    #
    def has_special_user_path(path, name=nil)
      self.has_special_path %r[/Users/.*/#{path.to_s}], name
    end

    #-----------------------------------------------------------------------------#

    # @!group Interaction

    # Runs the executable with the given arguments in the temporary directory.
    #
    # @note: You can check by `$?.success?` if the execution succeeded.
    #
    # @param [String] arguments
    #        The arguments to pass to the executable
    #
    # @return [String]
    #         The output, which is emitted while execution from the binary.
    #
    def launch(arguments)
      vars = environment_vars.map { |key,value| "#{key}=#{value}" }.join ' '
      args = "#{arguments} #{default_args.join(' ')}"
      command = "#{vars} #{executable} #{args} 2>&1"

      output = `#{command}`

      File.open(output_path, 'w') do |file|
        file.write command.sub(executable, name)

        special_paths.each do |key, path|
          output.gsub!(path, key)
        end

        file.write output
      end

      output
    end

  end
end
