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
      errors.add(:vegetarians, "Er kunnen niet meer vegetariërs (#{vegetarians}) dan gasten (#{attendees_list.size}) zijn.")
    end
  end

  validates_presence_of :attendees, :message => "De gastenlijst mag niet leeg zijn."
  validate :not_more_vegetarians_than_attendees
end

helpers do
  def address(singular_form, plural_form, amount = nil)
    amount ||= @invitation.attendees_list.size
    amount == 1 ? singular_form : plural_form
  end

  def update_invitation_form_tag
    %{<form action="/invitations/#{@invitation.id}" method="post">}
  end

  def textfield(attr, style)
    error = false
    if ary = @invitation.errors[attr]
      error = !ary.empty?
    end
    %{<input type="text" name="invitation[#{attr}]" value="#{@invitation.send(attr)}" #{'class="error"' if error} style="#{style}" />}
  end

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
  erb(@invitation.confirmed? ? :confirmation : :invitation)
end

get '/invitations/:id/confirm' do |id|
  @invitation = Invitation.find(id)
  erb :confirmation
end

post '/invitations/:id' do |id|
  @invitation = Invitation.find(id)
  if @invitation.update_attributes(params[:invitation])
    if @invitation.confirmed?
      redirect to("/invitations/#{id}")
    else
      redirect to("/invitations/#{id}/confirm")
    end
  else
    erb :invitation
  end
end
