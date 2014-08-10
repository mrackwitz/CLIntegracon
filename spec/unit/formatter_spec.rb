require File.expand_path('../spec_helper', __FILE__)

describe CLIntegracon::Formatter do

  def subject
    CLIntegracon::Formatter
  end

  before do
    @spec = stub('Spec', spec_folder: '$spec_folder')
  end

  describe "#initialize" do
    it 'should set given spec as attribute' do
      @formatter = subject.new(@spec)
      @formatter.spec.should.should.eql?(@spec)
    end
  end

  shared 'has_formatting_methods' do
    describe '#respond_to?' do
      it 'should respond to #describe_missing_file' do
        @formatter.respond_to?(:describe_missing_file).should.be.true?
      end

      it 'should respond to #describe_unexpected_files' do
        @formatter.respond_to?(:describe_unexpected_files).should.be.true?
      end

      it 'should respond to #describe_file_diff' do
        @formatter.respond_to?(:describe_file_diff).should.be.true?
      end
    end

    describe "#describe_missing_file" do
      it 'should match the expected return value' do
        @formatter.describe_missing_file('$missing').to_s.should.be.eql?  <<-EOS.chomp
Missing file for $spec_folder:
  * \e[31m$missing\e[0m
EOS
      end
    end

    describe "#describe_unexpected_files" do
      it 'should match the expected return value' do
        @formatter.describe_unexpected_files(['$a', '$b']).to_s.should.be.eql? <<-EOS.chomp
Unexpected files for $spec_folder:
  * \e[32m$a\e[0m
  * \e[32m$b\e[0m
EOS
      end
    end

    describe "#describe_file_diff" do
      it 'should match the expected return value' do
        diff = ['$before', '+ $add', '- $removed', '$after']
        diff.stubs(relative_path: '$relative_path')
        @formatter.describe_file_diff(diff, 20).to_s.should.be.eql? <<-EOS
File comparison error `$relative_path` for $spec_folder:
--- DIFF -----------
$before
\e[32m+ $add\e[0m
\e[31m- $removed\e[0m
$after
--- END ------------
EOS
      end
    end
  end

  describe 'has formatting methods' do
    before do
      @formatter = subject.new(@spec)
    end

    behaves_like 'has_formatting_methods'
  end

  describe "#lazy" do
    before do
      @formatter = subject.new(@spec)
    end

    describe '#respond_to?' do
      it 'should not respond to additional methods' do
        @formatter.lazy.respond_to?(:describe_foo).should.be.false?
        @formatter.lazy.respond_to?(:lazy).should.be.false?
      end
    end

    describe 'delegates to formatting methods' do
      before do
        @formatter = subject.new(@spec).lazy
      end

      behaves_like 'has_formatting_methods'
    end

    describe '#describe_missing_file' do
      it 'should not call the method immediately' do
        @formatter.expects(:describe_missing_file).never
        @formatter.lazy.describe_missing_file('a')
          .should.be.an.instance_of?(CLIntegracon::LazyString)
      end
    end

    describe "#describe_unexpected_files" do
      it 'should not call the method immediately' do
        @formatter.expects(:describe_unexpected_files).never
        @formatter.lazy.describe_unexpected_files(['a', 'b'])
          .should.be.an.instance_of?(CLIntegracon::LazyString)
      end
    end

    describe "#describe_file_diff" do
      it 'should not call the method immediately' do
        @formatter.expects(:describe_missing_file).never
        @formatter.lazy.describe_file_diff(stub('Diff'))
          .should.be.an.instance_of?(CLIntegracon::LazyString)
      end
    end
  end

end
