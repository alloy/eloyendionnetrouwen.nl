require 'config'
require 'invitation'
require 'helpers'
require 'mailer'

helpers do
  include Helpers
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
      Mailer.send_confirmation(@invitation) if @invitation.email
      redirect to("/invitations/#{id}")
    else
      redirect to("/invitations/#{id}/confirm")
    end
  else
    erb :invitation
  end
end
