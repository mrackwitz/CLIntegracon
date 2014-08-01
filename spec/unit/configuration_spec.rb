require 'CLIntegracon'
require 'mocha-on-bacon'

describe CLIntegracon do

  def subject
    CLIntegracon
  end

  describe '#self.configure' do

    after do
      subject.shared_config = nil
    end

    it 'should call the given block' do
      proc = Proc.new {}
      proc.expects(:call).once
      subject.configure { proc.call() }
    end

    it 'should pass the shared_config as parameter to the given block' do
      shared_config = mock()
      subject.stubs(:shared_config).returns(shared_config)
      subject.configure do |c|
        c.should.be.equal? shared_config
      end
    end

    it 'should instantiate and keep a new shared config if no was given' do
      subject.shared_config = nil
      subject.configure {}
      subject.shared_config.should.be.an.instance_of? CLIntegracon::Configuration
    end

    it 'should keep the existing config if there is one' do
      shared_config = mock()
      subject.shared_config = shared_config
      subject.configure {}
      subject.shared_config.should.be.equal? shared_config
    end

  end

  describe CLIntegracon::Configuration do

    def subject
      CLIntegracon::Configuration
    end

    describe '#self.adapters' do

      it 'should include :bacon' do
        subject.adapters.should.include? :bacon
        File.exists?(subject.adapters[:bacon]).should.be.true?
      end

    end

    describe '#hook_into' do

      it 'should include the corresponding implementation file' do
        config = subject.new
        config.expects(:require).with(subject.adapters[:bacon])
        config.hook_into :bacon
      end

    end

  end

end
