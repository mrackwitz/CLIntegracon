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
        @context.should.respond_to? :file_tree_spec_context
        @context.should.respond_to? :cli_spec
        @context.should.respond_to? :file_spec
      end
    end

    describe 'extends context with methods' do
      before do
        defines_specs.once
        @context = describe_cli('test') {}
      end

      behaves_like 'extended context'
    end

    describe 'extends inner context with methods' do
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

    MockContext = Class.new do
      include CLIntegracon::Adapter::Bacon::Context
    end

    before do
      @context = MockContext.new
    end


    shared 'mutating accessor' do

      before do
        def call_accessor(&block)
          @context.send(@method, &block)
        end

        def set_ivar(value)
          @context.instance_variable_set("@#{@method.to_s}", value)
        end

        def get_ivar
          @context.instance_variable_get("@#{@method.to_s}")
        end
      end

      describe 'with block argument' do
        it 'should call the given block' do
          proc = Proc.new {}
          proc.expects(:call).once
          call_accessor { proc.call() }
        end

        it 'should pass it as parameter to the given block' do
          mock = mock()
          set_ivar(mock)
          call_accessor do |arg|
            arg.should.be.equal? mock
          end
        end

        it 'should get and keep a new if ivar is empty' do
          set_ivar(nil)
          call_accessor {}
          get_ivar.should.be.an.instance_of? @type
        end

        it 'should get a new by duplicating from shared config' do
          CLIntegracon.shared_config.expects(@method).returns mock(:dup)
          call_accessor
        end

        it 'should keep the existing if there is one' do
          mock = mock()
          set_ivar(mock)
          call_accessor {}
          get_ivar.should.be.equal? mock
        end
      end

      describe 'with block argument' do
        it 'should instantiate and keep a new if ivar is empty' do
          set_ivar(nil)
          call_accessor.should.be.an.instance_of? @type
          get_ivar.should.be.an.instance_of? @type
        end

        it 'should return the existing if there is one' do
          mock = mock()
          set_ivar(mock)
          call_accessor.should.be.equal? mock
        end
      end
    end


    describe '#subject' do
      before do
        @method = :subject
        @type = CLIntegracon::Subject
      end

      behaves_like 'mutating accessor'
    end

    describe '#file_tree_spec_context' do
      before do
        @method = :file_tree_spec_context
        @type = CLIntegracon::FileTreeSpecContext
      end

      behaves_like 'mutating accessor'
    end

    describe '#file_spec' do

      before do
        defines_specs.once
        CLIntegracon::FileTreeSpec.any_instance.stubs(:run)
      end

      it 'knows the on-the-fly defined shared behavior' do
        describe_cli 'git' do
          lambda {
            behaves_like file_spec('any_dir')
          }.should.not.raise?(NameError)
        end
      end

      it 'executes the FileTreeSpecContext' do
        describe_cli 'git' do
          file_tree_spec_context.expects(:spec).once.returns mock(:run => true)
          behaves_like file_spec('git')
        end
      end

    end

  end

end
