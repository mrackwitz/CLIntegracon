require 'pathname'
require 'colored'
require 'diffy'

module CLIntegracon
  class Diff
    include Enumerable

    # @return [Pathname]
    #         the expected file
    attr_reader :expected

    # @return [Pathname]
    #         the produced file
    attr_reader :produced

    # @return [Pathname]
    #         the relative path to the expected file
    attr_reader :relative_path

    # @return [Proc<(Pathname)->(to_s)>]
    #         the proc, which transforms the files in a better comparable form
    attr_accessor :preparator

    # Init a new diff
    #
    # @param [Pathname] expected
    #        the expected file
    #
    # @param [Pathname] produced
    #        the produced file
    #
    # @param [Pathname] relative_path
    #        the relative path to the expected file
    #
    # @param [Block<(Pathname)->(to_s)>] preparator
    #        the block, which transforms the files in a better comparable form
    #
    def initialize(expected, produced, relative_path=nil, &preparator)
      @expected = expected
      @produced = produced
      @relative_path = relative_path
      preparator ||= Proc.new { |x| x } #id
      self.preparator = preparator
    end

    def prepared_expected
      @prepared_expected ||= preparator.call(expected)
    end

    def prepared_produced
      @prepared_produced ||= preparator.call(produced)
    end

    # Check if the prepared inputs are files or need to be dumped first to
    # temporary files to be compared.
    #
    # @return [Bool]
    #
    def compares_files?
      prepared_expected.is_a? Pathname
    end

    # Check if the produced output equals the expected
    #
    # @return [Bool]
    #         whether the expected is equal to the produced
    #
    def is_equal?
      @is_equal ||= if compares_files?
        FileUtils.compare_file(prepared_expected, prepared_produced)
      else
        prepared_expected == prepared_produced
      end
    end

    # Enumerate all lines which differ.
    #
    # @param  [Hash] options
    #         see Diffy#initialize for help.
    #
    # @return [Diffy::Diff]
    #
    def each(options = {}, &block)
      options = {
        :source  => compares_files? ? 'files' : 'strings',
        :context => 3
      }.merge options
      Diffy::Diff.new(prepared_expected.to_s, prepared_produced.to_s, options).each &block
    end

  end
end
