begin
  require 'bundler/gem_tasks'
  require 'colored'

  namespace :spec do

    task :prepare do
      verbose false
      puts 'Prepare …'
      sh 'mkdir -p tmp'
      rm_rf 'tmp/*'
    end

    desc 'Run the bacon integration spec'
    task :bacon_integration => [:prepare] do
      verbose false
      sh 'bundle exec bacon spec/bacon/spec_helper.rb > tmp/bacon_execution_output.txt'
      puts 'Run bacon spec …'
      sh 'diff spec/bacon/execution_output.txt tmp/bacon_execution_output.txt' do |ok, res|
        if ok
          puts '✓ Spec for bacon passed.'.green
        else
          puts '✗ Spec for bacon failed.'.red
        end
      end
    end

    desc 'Run all integration specs'
    task :integration => [
      'spec:bacon_integration'
    ]

    desc 'Run all unit specs'
    task :unit do
      sh "bundle exec bacon #{specs('unit/**/*')}"
    end

    def specs(dir)
      FileList["spec/#{dir}_spec.rb"].shuffle.join(' ')
    end

    desc 'Run all specs'
    task :all => [:unit, :integration]

  end

  desc 'Run all specs'
  task :spec => 'spec:all'
end
