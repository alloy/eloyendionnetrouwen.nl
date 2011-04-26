module Helpers
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
