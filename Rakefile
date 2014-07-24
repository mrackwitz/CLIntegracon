#encoding: utf-8

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
      sh 'rake spec:bacon_integration_runner > tmp/bacon_execution_output.txt' do; end
      puts 'Run bacon spec …'
      sh 'diff spec/bacon/execution_output.txt tmp/bacon_execution_output.txt' do |ok, res|
        if ok
          puts '✓ Spec for bacon passed.'.green
        else
          puts '✗ Spec for bacon failed.'.red
        end
      end
    end

    desc 'Run the tasks for bacon integration spec verbose and without any outer expectations'
    task :bacon_integration_runner do
      sh [
        'bundle exec bacon spec/bacon/spec_helper.rb',
        'sed -e "s|$(echo $GEM_HOME)|\$GEM_HOME|g"',
        'sed -e "s|$(dirname ~/.)|\$HOME|g"'
      ].join " | "
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
