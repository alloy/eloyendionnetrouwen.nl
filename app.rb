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
  def attendees=(attendees)
    write_attribute :attendees, list(attendees).reject(&:empty?).join(", ")
  end

  def attendees_list
    list(attendees)
  end

  def attendees_sentence
    list = attendees_list
    if list.size == 1
      list.first
    else
      list[0..-2].join(", ") << " en #{list.last}"
    end
  end

  private

  def list(str)
    str.split(",").map { |a| a.strip }
  end

  validates_presence_of :attendees
end

get '/' do
  erb :index
end

get '/:invitation_id' do |id|
  redirect to("/invitations/#{id}")
end

get '/invitations/:id' do |id|
  @invitation = Invitation.find(id)
  erb :invitation
end

post '/invitations/:id' do |id|
  @invitation = Invitation.find(id)
  @invitation.update_attributes(params[:invitation])
  redirect to("/invitations/#{id}")
end
