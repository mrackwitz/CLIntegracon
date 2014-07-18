require 'CLIntegracon'
require 'mocha-on-bacon'

describe 'CLIntegracon::Adapter::Bacon' do

  CLIntegracon.configure do
    hook_into :bacon
  end

  # Mutes specs from output
  def defines_specs
    Bacon.expects(:handle_specification).yields
  end

  describe '#describe_cli' do

    it 'is globally available' do
      defines_specs.once
      describe_cli('test') {}.should.be.an.instance_of? Bacon::Context
    end

    it 'is available for Bacon::Context' do
      defines_specs.twice
      describe('test') do
        describe_cli('test') {}.should.be.an.instance_of? Bacon::Context
      end
    end

    shared 'extended context' do
      it 'can access #describe_cli' do
        @context.should.respond_to? :describe_cli
      end

      it 'can access to methods defined in CLIntegracon::Adapter::Bacon::Context' do
        @context.should.respond_to? :subject
        @context.should.respond_to? :context
        @context.should.respond_to? :behaves_like_a
      end
    end

    describe 'extends context with methods' do
      before do
        defines_specs.once
        @context = describe_cli('test') {}
      end

      behaves_like 'extended context'
    end

    describe 'extends context with methods' do
      before do
        defines_specs.twice
        parent_context = self
        describe_cli('test') do
          @context = describe('inner') {}
          parent_context.instance_variable_set '@context', @context
        end
      end

      behaves_like 'extended context'
    end

  end

  describe 'Context' do

    describe '#subject' do
      # TODO
    end

    describe '#context' do
      # TODO
    end

    describe '#behaves_like_a' do

      before do
        defines_specs.once
        CLIntegracon::FileTreeSpec.any_instance.stubs(:run)
      end

      it 'knows the implicit defined shared behavior' do
        describe_cli 'git' do
          lambda {
            behaves_like_a 'git', dir: 'git'
          }.should.not.raise?(NameError)
        end
      end

      it 'executes the FileTreeSpecContext' do
        describe_cli 'git' do
          context.expects(:spec).once.returns mock(run: true)
          behaves_like_a 'git', dir: 'git'
        end
      end

    end

  end

end
