require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord/rake'

namespace :db do
  namespace :migrate do
    task :test do
      set :environment, :test
      require 'app'
      Rake::Task['db:migrate'].invoke
    end
  end
end
