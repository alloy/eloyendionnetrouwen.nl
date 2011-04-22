require 'sinatra'
require 'erb'

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
