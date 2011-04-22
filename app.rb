require 'sinatra'
require 'erb'
require 'sinatra/activerecord'

set :database, "sqlite://#{Sinatra::Application.environment}.db"
set :root, File.expand_path('../', __FILE__)
#set :database, "mysql://localhost/eloyendionnetrouwen-#{Sinatra::Application.environment}"

class Invitation < ActiveRecord::Base
end

get '/' do
  erb :index
end

get '/:invitation_id' do
  erb :invitation
end

post '/invitations/:id' do |id|
  p params
  redirect to("/invitations/#{id}")
end
