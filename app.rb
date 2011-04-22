require 'sinatra'
require 'erb'
require 'sinatra/activerecord'

app = Sinatra::Application
set :database, "sqlite://#{app.environment}.db"
set :root, File.expand_path('../', __FILE__)
#set :database, "mysql://localhost/eloyendionnetrouwen-#{Sinatra::Application.environment}"

require 'logger'
ActiveRecord::Base.logger = Logger.new(File.join(app.root, 'log', "#{app.environment}.log"))

class Invitation < ActiveRecord::Base
  def attendees_list
    attendees.split(",").map { |a| a.strip }
  end
end

get '/' do
  erb :index
end

get '/:invitation_id' do
  erb :invitation
end

post '/invitations/:id' do |id|
  invitation = Invitation.find(id)
  invitation.update_attributes(params[:invitation])
  redirect to("/invitations/#{id}")
end
