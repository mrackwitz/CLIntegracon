require 'pathname'
require 'colored'
require 'diffy'

module CLIntegracon
  class Diff

    # @return [Pathname]
    #         the expected file
    attr_reader :expected

    # @return [Pathname]
    #         the produced file
    attr_reader :produced

    # @return [Proc<(Pathname)->(to_s)>]
    #         the proc, which transforms the files in a better comparable form
    attr_accessor :preparator

    # Init a new diff
    #
    # @param [Pathname] expected
    #        the expected file or string
    #
    # @param [Pathname] produced
    #        the produced file or string
    #
    # @param [Block<(Pathname)->(to_s)>] preparator
    #        the block, which transforms the files in a better comparable form
    #
    def initialize(expected, produced, &preparator)
      @expected = expected
      @produced = produced
      preparator ||= Proc.new { |x| x } #id
      self.preparator = preparator
    end

    def prepared_expected
      @prepared_expected ||= preparator.call(expected)
    end

    def prepared_produced
      @prepared_produced ||= preparator.call(produced)
    end

    # Check if the produced output equals the expected
    #
    # @return [Bool]
    #         whether the expected is equal to the produced
    #
    def is_equal?
      @is_equal ||= if prepared_expected.is_a? Pathname
        FileUtils.compare_file(prepared_expected, prepared_produced)
      else
        prepared_expected == prepared_produced
      end
    end

    def pretty_print(max_width=80)
      description = []
      description << "--- DIFF ".ljust(max_width, '-')
      Diffy::Diff.new(prepared_expected.to_s, prepared_produced.to_s, :source => 'files', :context => 3).each do |line|
        description << case line
          when /^\+/ then line.green
          when /^-/ then  line.red
          else            line
        end.gsub("\n",'')
      end
      description << "--- END ".ljust(max_width, '-')
      description << ""
      description * "\n"
    end

  end
end
