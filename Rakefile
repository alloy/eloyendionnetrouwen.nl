require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord/rake'

$:.unshift File.expand_path('../', __FILE__)

namespace :db do
  namespace :migrate do
    [:test, :development, :production].each do |env|
      task env do
        ENV['RACK_ENV'] = env.to_s
        sh "mysqladmin create eloyendionnetrouwen-production" if env == :production
        require 'app'
        Rake::Task['db:migrate'].invoke
      end
    end
  end

  namespace :recreate do
    [:test, :development].each do |env|
      task env do
        rm_f "#{env}.db"
        Rake::Task["db:migrate:#{env}"].invoke
      end
    end

    task :production do
      sh "mysqladmin drop eloyendionnetrouwen-production"
      Rake::Task['db:migrate:production'].invoke
    end
  end

  task :seed => 'db:seed:development'

  namespace :seed do
    [:development, :production].each do |env|
      task env => ["db:recreate:#{env}", :restart] do
        require 'app'
        tokens = []
        tokens << Invitation.create(:attendees => 'Bassie, Adriaan', :email => 'bassie@example.org').token
        tokens << Invitation.create(:attendees => 'Rini, Sander, Mats, Mila, Nena, Jacky, Yuka', :email => 'rini@example.org').token
        puts
        puts "Start by using either of these URLs:"
        tokens.each do |token|
          puts "  http://eloyendionnetrouwen.local/#{token}"
        end
      end
    end
  end

  task :recreate => ['db:recreate:test', 'db:seed']
end

desc 'Run tests'
task :test do
  sh "ruby -I. -r #{FileList['test/*_test.rb'].map { |f| f[0..-4] }.join(' -r ')} -e ''"
end

desc 'Restart Passenger'
task :restart do
  sh 'touch tmp/restart.txt'
end

namespace :send_invitations do
  [:development, :production].each do |env|
    task env do
      set :environment, env
      require 'invitation'
      Invitation.send_invitations!
    end
  end
end
