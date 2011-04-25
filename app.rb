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
  def vegetarians=(amount)
    write_attribute :vegetarians, amount.to_i
  end

  def omnivores
    attendees_list.size - vegetarians
  end

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

  def attending?
    attending_wedding? || attending_party?
  end

  private

  def list(str)
    str.split(",").map { |a| a.strip }
  end

  def not_more_vegetarians_than_attendees
    if vegetarians > attendees_list.size
      errors.add(:vegeterians, "Er kunnen niet meer vegetariërs (#{vegetarians}) dan gasten (#{attendees_list.size}) zijn.")
    end
  end

  validates_presence_of :attendees, :message => "De gastenlijst mag niet leeg zijn."
  validate :not_more_vegetarians_than_attendees
end

helpers do
  def checkbox(attr, label)
    %{<input type="hidden" name="invitation[#{attr}]" value="0" />
      <label>
        <input type="checkbox" id="#{attr}_input" name="invitation[#{attr}]" value="1" #{'checked="checked"' if @invitation.send(attr)} />
        #{label}
      </label>}
  end
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
  if @invitation.update_attributes(params[:invitation])
    redirect to("/invitations/#{id}/confirm")
  else
    erb :invitation
  end
end

get '/invitations/:id/confirm' do |id|
  @invitation = Invitation.find(id)
  erb :confirmation
end
