require 'pathname'

module CLIntegracon

  class << self

    # @return [Configuration]
    #         Get the shared configuration, set by {self.configure}.
    attr_accessor :shared_config

    # Set a new shared configuration
    #
    # @param  [Block<() -> ()>] block
    #         the block which is evaluated on the new shared configuration
    #
    def configure(&block)
      self.shared_config ||= Configuration.new
      shared_config.instance_eval &block
    end

  end

  class Configuration

    # Get the context to configure it
    #
    # @return [FileTreeSpecContext]
    #
    def context
      @context ||= FileTreeSpecContext.new()
    end

    # Hook this gem in a test framework by a supported adapter
    #
    # @param  [Symbol] test_framework
    #         the test framework
    #
    def hook_into test_framework
      adapter = self.class.adapters[test_framework]
      raise ArgumentError.new "No adapter for test framework #{test_framework}" if adapter.nil?
      require adapter
    end

    private

    # Get the file paths of supported adapter implementations by test framework
    #
    # @return [Hash<Symbol, String>]
    #         test framework to adapter implementation files
    #
    def self.adapters
      adapter_dir = Pathname('../adapter').expand_path(__FILE__)
      @adapters ||= Dir.chdir(adapter_dir) do
        Hash[Dir['*.rb'].map { |path| [path.gsub(/\.rb$/, '').to_sym, adapter_dir + path] }]
      end
    end

  end
end
