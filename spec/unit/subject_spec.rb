require File.expand_path('../spec_helper', __FILE__)

describe CLIntegracon::Subject do

  def subject
    CLIntegracon::Subject
  end

  before do
    @subject = subject.new('cat')
  end

  describe '#launch' do
    it 'should redact paths from output' do
      output = <<-eos.strip_heredoc
        /Users/marius/.im/chat.log
        /tmp/im/chat.log
      eos
      @subject.expects(:`).returns(output)
      @subject.stubs(:write_output)
      @subject.replace_user_path '.im/chat.log'
      @subject.replace_path '/tmp', '$TMP'
      @subject.launch.should.be == <<-eos.strip_heredoc
        $HOME/.im/chat.log
        $TMP/im/chat.log
      eos
    end
  end

end
