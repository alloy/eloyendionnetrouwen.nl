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
    p Invitation.create(:attendees => 'Bassie, Adriaan').id
    p Invitation.create(:attendees => 'Rini, Sander, Mats, Mila, Nena, Jacky, Yuka').id
  end
end
