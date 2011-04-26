require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord/rake'

namespace :db do
  namespace :migrate do
    task :development do
      set :environment, :development
      require 'app'
      Rake::Task['db:migrate'].invoke
    end

    task :test do
      set :environment, :test
      require 'app'
      Rake::Task['db:migrate'].invoke
    end
  end

  task :seed do
    require 'app'
    p Invitation.create(:attendees => 'Bassie, Adriaan', :email => 'bassie@caravan.es').id
    p Invitation.create(:attendees => 'Rini, Sander, Mats, Mila, Nena, Jacky, Yuka', :email => 'rini@example.org').id
  end
end

desc 'Run tests'
task :test do
  sh "ruby -r #{FileList['test/*_test.rb'].join(' -r ')} -e ''"
end

desc 'Restart Passenger'
task :restart do
  sh 'touch tmp/restart.txt'
end

desc 'Send invitations'
task :send_invitations do
  set :environment, :development
  require 'invitation'
  Invitation.send_invitations!
end
