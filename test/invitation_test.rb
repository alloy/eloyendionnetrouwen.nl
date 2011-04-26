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

  it "ensures that attending_party is set if the attendee attends the dinner, but not the reverse" do
    assert !@invitation.attending_party?
    @invitation.update_attributes :attending_dinner => true, :attending_party => false
    assert @invitation.reload.attending_party?
    @invitation.update_attributes :attending_dinner => false
    assert @invitation.reload.attending_party?
  end
end
