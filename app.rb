require 'sinatra'
require 'erb'

get '/' do
  erb :index
end

get '/:invitation_id' do
  erb :invitation
end
