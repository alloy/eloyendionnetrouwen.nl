require 'config'
require 'invitation'

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
