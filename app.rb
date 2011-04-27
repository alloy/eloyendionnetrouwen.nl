require 'config'
require 'invitation'
require 'helpers'
require 'mailer'

helpers do
  include Helpers
end

not_found do
  erb(:not_found)
end

get '/' do
  erb :index
end

get '/:invitation_token' do |token|
  redirect to("/invitations/#{token}")
end

get '/invitations/:token' do |token|
  if @invitation = Invitation.find_by_token(token)
    erb(@invitation.confirmed? ? :confirmation : :invitation)
  else
    404
  end
end

get '/invitations/:token/confirm' do |token|
  if @invitation = Invitation.find_by_token(token)
    erb :confirmation
  else
    404
  end
end

post '/invitations/:token' do |token|
  if @invitation = Invitation.find_by_token(token)
    if @invitation.update_attributes(params[:invitation])
      if @invitation.confirmed?
        Mailer.send_confirmation(@invitation) if @invitation.email
        redirect to("/invitations/#{token}")
      else
        redirect to("/invitations/#{token}/confirm")
      end
    else
      erb :invitation
    end
  else
    404
  end
end
