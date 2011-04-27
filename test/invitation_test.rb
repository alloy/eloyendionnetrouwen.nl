require File.expand_path('../test_helper', __FILE__)

class InvitationTest < Test::Unit::TestCase
  def setup
    @invitation = Invitation.new(:attendees => 'Bassie, Adriaan', :email => 'bassie@caravan.es')
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

  it "is invalid with an invalid email" do
    assert @invitation.valid?
    @invitation.email = '.foo@example.com'
    assert !@invitation.valid?
    @invitation.email = "  "
    assert @invitation.valid?
  end

  it "generates a unique token" do
    def @invitation.generate_token
      'a1b2'
    end
    @invitation.save!
    assert_equal 'a1b2', @invitation.reload.token

    invitation2 = Invitation.new(:attendees => 'Rogier, Fransje', :email => 'rogier@example.org')
    def invitation2.generate_token
      def self.generate_token
        # 2: this token will be returned the second time when the method has been overwritten by this implementation
        'c3d4'
      end
      # 1: this token will be returned first which is a duplicate of @invitation.token
      'a1b2'
    end
    invitation2.save!
    assert_equal 'c3d4', invitation2.reload.token
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
    @invitation.english = true
    assert_equal 'Rini, Sander, Mats, Mila, Nena, Jacky, and Yuka', @invitation.attendees_sentence
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

  it "sanitizes the email address to not be empty" do
    @invitation.email = ""
    assert_nil @invitation.email
    @invitation.email = "  "
    assert_nil @invitation.email
    @invitation.email = "\t  \n  "
    assert_nil @invitation.email
  end

  it "sends invitation emails to those that have not received one yet and have an email address" do
    invitation1 = Invitation.create!(:attendees => 'Bassie', :email => 'bassie@caravan.es')
    invitation2 = Invitation.create!(:attendees => 'Rogier, Fransje', :email => 'rogier@example.org')
    invitation3 = Invitation.create!(:attendees => 'Laurent, Stephanie, Alexis', :email => 'lrz@example.org', :english => true)
    invitation4 = Invitation.create!(:attendees => 'Tomas, Daphne', :email => 'tomas@example.org', :sent => true)
    invitation5 = Invitation.create!(:attendees => 'Opa, Oma', :email => '')
    Invitation.send_invitations!
    [invitation1, invitation2, invitation3, invitation4, invitation5].each(&:reload)
    emails = Net::SMTP.sent_emails

    assert_equal 3, emails.size

    assert invitation1.sent?
    assert_equal FROM_EMAIL, emails[0].from
    assert_equal invitation1.email, emails[0].to
    assert emails[0].message.include?("Bassie,")
    assert emails[0].message.include?("http://eloyendionnetrouwen.nl/#{invitation1.token}")

    assert invitation2.sent?
    assert_equal FROM_EMAIL, emails[1].from
    assert_equal invitation2.email, emails[1].to
    assert emails[1].message.include?("Rogier en Fransje,")
    assert emails[1].message.include?("http://eloyendionnetrouwen.nl/#{invitation2.token}")

    assert invitation3.sent?
    assert_equal FROM_EMAIL, emails[2].from
    assert_equal invitation3.email, emails[2].to
    assert emails[2].message.include?("Laurent, Stephanie, and Alexis")
    assert !emails[2].message.include?("http://eloyendionnetrouwen.nl/#{invitation2.token}")
    assert emails[2].message.include?("Reply to this email")

    assert !invitation5.sent?
  end
end
