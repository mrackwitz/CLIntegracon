require 'CLIntegracon'

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

end
