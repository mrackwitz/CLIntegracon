require 'CLIntegracon'

describe 'CLIntegracon::Adapter::Bacon' do

  describe '#describe_cli' do

    # These specs are executed in a sub-shell, to ensure we don't get any output we don't want.
    def evaluate_expr(expression)
      code = <<-eos
        CLIntegracon.configure do
          hook_into :bacon
        end

        exit 1 unless #{expression}
      eos
      `bundle exec ruby -r 'bacon' -I 'lib' -r 'CLIntegracon' -e "#{code.gsub('"', '\\"')}"`
      $?
    end

    it 'is globally available' do
      evaluate_expr("describe_cli('test') {}.is_a? Bacon::Context").should.success?
    end

    it 'is available for Bacon::Context' do
      evaluate_expr("describe('test') { describe_cli('test') {}.is_a? Bacon::Context }").should.success?
    end

  end

end
