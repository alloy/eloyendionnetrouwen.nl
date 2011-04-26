require File.expand_path('../test_helper', __FILE__)

class InviteeTest < Test::Unit::TestCase
  def setup
    @invitation = Invitation.create(:attendees => 'Bassie, Adriaan', :email => 'bassie@caravan.es')
  end

  def teardown
    Invitation.delete_all
  end

  it "is redirected to the actual invitation page" do
    get "/#{@invitation.id}"
    assert last_response.redirect?
    assert_equal "http://example.org/invitations/#{@invitation.id}", last_response.headers['Location']
  end

  it "sees an invitation page" do
    get "/invitations/#{@invitation.id}"
    assert last_response.ok?
    assert_have_tag "form[@action=\"/invitations/#{@invitation.id}\"][@method=post]" do
      assert_have_tag 'input[@name="invitation[attendees]"][@value="Bassie, Adriaan"]'
      assert_have_tag 'input[@name="invitation[email]"][@value="bassie@caravan.es"]'
    end
  end

  it "confirms who will be attending" do
    update_invitation :attendees => 'Bassie, Adriaan'
    assert_equal %w{ Bassie Adriaan }, @invitation.attendees_list
    update_invitation :attendees => 'Bassie'
    assert_equal %w{ Bassie }, @invitation.attendees_list
  end

  it "confirms if they'll attend the wedding itself" do
    update_invitation :attending_wedding => '0'
    assert !@invitation.attending_wedding?
    update_invitation :attending_wedding => '1'
    assert @invitation.attending_wedding?
  end

  it "confirms if they'll attend the party" do
    update_invitation :attending_party => '0'
    assert !@invitation.attending_party?
    update_invitation :attending_party => '1'
    assert @invitation.attending_party?
  end

  it "confirms if they'll attend dinner" do
    update_invitation :attending_dinner => '0'
    assert !@invitation.attending_dinner?
    update_invitation :attending_dinner => '1'
    assert @invitation.attending_dinner?
  end

  it "confirms how many vegetarians there are" do
    update_invitation :vegetarians => '0'
    assert_equal 0, @invitation.vegetarians
    update_invitation :vegetarians => '2'
    assert_equal 2, @invitation.vegetarians
  end

  it "shows the form with validation errors" do
    post "/invitations/#{@invitation.id}", :invitation => { :attendees => '', :vegetarians => 3 }
    assert last_response.ok?
    assert_have_tag 'li', :content => "De gastenlijst mag niet leeg zijn."
    assert_have_tag 'li', :content => "Er kunnen niet meer vegetariërs (3) dan gasten (0) zijn."
    assert_have_tag "form[@action=\"/invitations/#{@invitation.id}\"][@method=post]" do
      assert_have_tag 'input[@name="invitation[vegetarians]"][@value="3"]'
    end
    assert_equal 0, @invitation.reload.vegetarians
  end

  it "sees a confirmation page" do
    get "/invitations/#{@invitation.id}/confirm"
    assert last_response.ok?
    assert_have_tag "form[@action=\"/invitations/#{@invitation.id}\"][@method=post]" do
      assert_have_tag 'input[@name="invitation[confirmed]"][@value="1"]'
    end
  end

  it "confirms the invitation" do
    update_invitation({ :confirmed => '1' }, "http://example.org/invitations/#{@invitation.id}")
    assert @invitation.confirmed?
  end

  it "shows a confirmed invitation page" do
    @invitation.update_attribute(:confirmed, true)
    get "/invitations/#{@invitation.id}"
    assert last_response.ok?
    assert_have_tag "form", :count => 0
  end

  it "addresses the attendee or attendees in the proper way" do
    get "/invitations/#{@invitation.id}"
    assert last_response.body.include?('komen jullie')
    assert !last_response.body.include?('kom je')
    @invitation.update_attribute(:attendees, 'Bassie')
    get "/invitations/#{@invitation.id}"
    assert !last_response.body.include?('komen jullie')
    assert last_response.body.include?('kom je')
  end

  private

  def update_invitation(invitation_attributes, redirect_to = nil)
    post "/invitations/#{@invitation.id}", :invitation => invitation_attributes
    assert last_response.redirect?
    assert_equal(redirect_to || "http://example.org/invitations/#{@invitation.id}/confirm", last_response.headers['Location'])
    @invitation.reload
  end
end

