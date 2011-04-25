require File.expand_path('../test_helper', __FILE__)

class InvitationTest < Test::Unit::TestCase
  def setup
    @invitation = Invitation.new(:attendees => 'Bassie, Adriaan', :email => 'bassie@caravan.es')
  end

  def teardown
    Invitation.delete_all
  end

  it "is invalid without any attendees" do
    assert @invitation.valid?
    @invitation.attendees = ''
    assert !@invitation.valid?
  end

  it "is invalid with more vegetarians than attendees" do
    assert @invitation.valid?
    @invitation.vegetarians = 1
    assert @invitation.valid?
    @invitation.vegetarians = 2
    assert @invitation.valid?
    @invitation.vegetarians = 3
    assert !@invitation.valid?
  end

  it "cleans the whitespace between the names" do
    @invitation.attendees = "Bassie, "
    assert_equal 'Bassie', @invitation.attendees
    @invitation.attendees = "Bassie,Adriaan"
    assert_equal 'Bassie, Adriaan', @invitation.attendees
    @invitation.attendees = "  Bassie\t \t,Adriaan   "
    assert_equal 'Bassie, Adriaan', @invitation.attendees
  end

  it "returns a sentence for the list of attendees" do
    assert_equal 'Bassie en Adriaan', @invitation.attendees_sentence
    @invitation.attendees = 'Greet'
    assert_equal 'Greet', @invitation.attendees_sentence
    @invitation.attendees = 'Rini, Sander, Mats, Mila, Nena, Jacky, Yuka'
    assert_equal 'Rini, Sander, Mats, Mila, Nena, Jacky en Yuka', @invitation.attendees_sentence
  end

  it "returns wether or not they will attend at all" do
    assert !@invitation.attending?
    @invitation.attending_wedding = true
    assert @invitation.attending?
    @invitation.attending_party = true
    assert @invitation.attending?
    @invitation.attending_wedding = false
    assert @invitation.attending?
    @invitation.attending_party = false
    assert !@invitation.attending?
  end

  it "ensures that #vegetarians isn't nil" do
    assert_equal 0, @invitation.vegetarians
    @invitation.vegetarians = ''
    assert_equal 0, @invitation.vegetarians
  end

  it "returns the amount of omnivores" do
    assert_equal 2, @invitation.omnivores
    @invitation.vegetarians = 1
    assert_equal 1, @invitation.omnivores
    @invitation.vegetarians = 2
    assert_equal 0, @invitation.omnivores
  end
end

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
  end

  private

  def update_invitation(invitation_attributes)
    post "/invitations/#{@invitation.id}", :invitation => invitation_attributes
    assert last_response.redirect?
    assert_equal "http://example.org/invitations/#{@invitation.id}/confirm", last_response.headers['Location']
    @invitation.reload
  end
end

