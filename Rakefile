begin
  require 'bundler/gem_tasks'
  require 'colored'

  namespace :spec do

    task :prepare do
      sh 'mkdir -p tmp'
      rm_rf 'tmp/*'
    end

    desc 'Run the bacon integration spec'
    task :bacon_integration => [:prepare] do
      sh 'bundle exec bacon spec/bacon/spec_helper.rb > tmp/bacon_execution_output.txt'
      sh 'diff spec/bacon/execution_output.txt tmp/bacon_execution_output.txt'
    end

    desc 'Run all integration specs'
    task :integration => [
      'spec:bacon_integration'
    ]

  end

  desc 'Run all specs'
  task :spec => ['spec:integration']
end
